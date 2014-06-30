display.setStatusBar(display.HiddenStatusBar)

require("strict")

local ExecutiveFactory = require("system.game")
local Executive = require("system.executive")
local Maze = require("classes.maze")

--- ************************************************************************************************************************************************************************
--							Base class for player/object views. Monitors a player for changing location and/or direction and requests update
--- ************************************************************************************************************************************************************************

local ViewObjectBase = Executive:createClass()

--//	Constructor.
--//	@info 	[table]		Constructor data containing the map.

function ViewObjectBase:constructor(info)
	self.m_player = nil 																		-- current player view is watching, currently nothing.
	self.m_xView = nil self.m_yView = nil self.m_direction = nil 								-- x, y and direction		
	self.m_maze = info.maze 																	-- maze in
	self:tag("+update,+changelistener") 														-- updateable object 
	self.m_object = nil 																		-- current display object
end 

--//	Messages are deemed to be refresh ones.

function ViewObjectBase:onMessage(sender,body)
	if body.name == "phantom" then self.m_xView = nil end 										-- phantom message, update display.
end


--//	Destructor

function ViewObjectBase:destructor()
	if self.m_object ~= nil then self.m_object:removeSelf() end 								-- remove current display object if any.
	self.m_object = nil 
end 

--//	Attach a player to a view - so you could have multiple players and switch between them.
--//	@player 	[Player]		Player being monitored

function ViewObjectBase:attach(player)
	self.m_player = player 																		-- store player.
	self.m_xView = nil 																			-- this invalidates 'current view' position, so it will be redrawn.
	self:onUpdate() 																			-- force update.
	return(self)
end 

--//	Handle enter frame events.

function ViewObjectBase:onUpdate()
	if self.m_player == nil then return end 													-- exit if no player attached.
	local nDirection = 1 - self.m_player.dx  													-- convert to 0,1,2,3
	if self.m_player.dy ~= 0 then nDirection = self.m_player.dy + 2 end 		
	if self.m_player.x ~= self.m_xView or self.m_player.y ~= self.m_yView or 
													self.m_direction ~= nDirection then 
		local posChange = self.m_player.x ~= self.m_xView or self.m_player.y ~= self.m_yView 	-- has position changed ?													
		self.m_xView = self.m_player.x self.m_yView = self.m_player.y 							-- update player position
		local turn = 0 																			-- work out turning.
		if self.m_direction ~= nil then turn = (nDirection - self.m_direction + 4) % 4 end
		self.m_direction = nDirection 															-- update direction
		self:updateView(self.m_player,turn,posChange) 											-- request an update.
	end
end 

--- ************************************************************************************************************************************************************************
--																				2D Map View
--- ************************************************************************************************************************************************************************

local MapView = ViewObjectBase:new()

--//	Constructor override, times out and self deletes after a periodm, one timer starts a fade out, the other actually removes it.

function MapView:constructor(info)
	ViewObjectBase.constructor(self,info) 														-- superclass constructor
	local timeOut = info.time or 10000  														-- how long before fading out
	self:addSingleTimer(timeOut,"fade") 														-- fire a timer after that time
	self:addSingleTimer(timeOut+2000,"remove") 													-- shortly after that, kill it.
	self.m_inFade = false  																		-- not fading yet
end 

--//	Timer called twice, once to start fade out transition, once to delete it.

function MapView:onTimer(tag, timerID)
	if tag == "fade" then  																		-- fade tag
		self.m_inFade = true  																	-- mark as fading so not updated
		transition.to(self.m_object, { time = 2000, alpha = 0 }) 								-- transition it out
	else 
		self:delete() 																			-- otherwise delete
	end
end

--//	Update the view
--//	@player 	[Player]		Player object
--//	@turn 		[Number]		amount of turn (clockwise) 0-3
--//	@posChange	[Boolean]		true if physically moved.

function MapView:updateView(player,turn,posChange)
	if self.m_inFade then return end 															-- fading out, do nothing
	if self.m_object ~= nil then self.m_object:removeSelf() end									-- remove old object 
	local renderer = self:getExecutive().e.map2Drender 											-- render it
	local m = renderer:render(self.m_maze,player,self:query("enemy").objects,display.contentWidth*0.3,display.contentHeight*0.3)
	m.x = display.contentWidth*2/3-5 m.y = 5 													-- position it
	m.alpha = 0.7 																				-- slightly transparent
	m:toFront() 																				-- bring it to the front.
	if self.m_object == nil then  																-- if new then transition it in.
		m.alpha = 0 transition.to(m, { time = 800, alpha = 0.7}) end 
	self.m_object = m
	self:insert(m) 																				-- add to group
end 

--- ************************************************************************************************************************************************************************
--																					3D Projection
--- ************************************************************************************************************************************************************************

local FrontView = ViewObjectBase:new()

--//	Update the view
--//	@player 	[Player]		Player object
--//	@turn 		[Number]		amount of turn (clockwise) 0-3
--//	@posChange	[Boolean]		true if physically moved.

function FrontView:updateView(player,turn,posChange)
	local phantoms = self:query("enemy").objects 												-- get hash (not array) of phantoms
	local renderer = self:getExecutive().e.map3Drender 											-- get renderer and render the display
	local m = renderer:render(self.m_maze,player,phantoms,display.contentWidth,display.contentHeight) 
	if self.m_object ~= nil then self.m_object:toBack() end 									-- send the old object right to the back

	self:insert(m) 																				-- add to group
	m:toBack() 																					-- and the new one behind that

	if posChange or (turn ~= 1 and turn ~= 3) or self.m_object == nil then 						-- is it a positional change, or a 180 degree turn, or first
		if self.m_object ~= nil then self.m_object:removeSelf() end								-- remove old object 
		self.m_object = m  																		-- make this object current object
	else 	
		local tTime = 250
		self:sendMessage("viewlistener",{name = "turn"}) 										-- we are turning
		if turn == 3 then  																		-- the rotational slide that phantom slayer does
			m.x = display.contentWidth 															-- clockwise
			transition.to(m,{ time = tTime, x = 0})
			transition.to(self.m_object,{ time = tTime, x = -display.contentWidth, onComplete = function(obj) obj:removeSelf() end})
			self.m_object = m
		else 
			m.x = -display.contentWidth 														-- anticlockwise
			transition.to(m,{ time = tTime, x = 0})
			transition.to(self.m_object,{ time = tTime, x = display.contentWidth, onComplete = function(obj) obj:removeSelf() end})
			self.m_object = m
		end 
	end
end 

function FrontView:onMessage(sender,body)
	if self.m_isDying then return end  															-- no more messages if dying.
	ViewObjectBase.onMessage(self,sender,body) 													-- pass message to subclass.
	if body.name == "die" then 																	-- dying, process that effect.
		transition.to(self.m_object,{ time = 5000, 												-- animate falling to floor, at the end go to next game state.
									  y = -display.contentHeight / 2, transition = easing.outElastic,
									  onComplete = function() self:sendMessage(sender,{name = "nextstate" }) end })
		transition.to(self.m_object,{ time = 3000, alpha = 0.25 }) 								-- put the lights out.
		local renderer = self:getExecutive().e.map3Drender 										-- get renderer
		local w = display.contentWidth local h = display.contentHeight
		local path = { 0,h,-w/4,h*2,w+w/4,h*2,w,h } 											-- create a floor to fall onto.
		local image = renderer:renderWall(path,"f")
		image:toBack()
		self.m_isDying = true
	end
end 

--- ************************************************************************************************************************************************************************
--																		Controller/Front Frame
--- ************************************************************************************************************************************************************************

local FrontController = Executive:createClass()

--// 	Create front display - click area, fire button and frame.

function FrontController:constructor(info) 
	self.m_clickScreen = display.newRect(0,0,display.contentWidth,display.contentHeight) 		-- nearly transparent screen to click on.
	self.m_clickScreen.anchorX,self.m_clickScreen.anchorY = 0,0 self.m_clickScreen.alpha = 0.01
	if info.retro then 																			-- fire button
		self.m_button = display.newCircle(display.contentWidth-10,display.contentHeight-10,32)
		self.m_button:setFillColor(1,0,0) self.m_button.strokeWidth = 2 self.m_button:setStrokeColor(0,0,0)
	else 																						-- image based version.
		self.m_button = display.newImage("images/button.png",										
												display.contentWidth-5,display.contentHeight-5)
	end
	self.m_button.anchorX,self.m_button.anchorY = 1,1 
	self.m_button.width,self.m_button.height = display.contentWidth/5,display.contentWidth/5
	self.m_clickScreen:addEventListener("tap",self) 											-- add tap listeners
	self.m_button:addEventListener("tap",self) 
	self.m_backButton = display.newImage("images/back.png",2,2) 								-- back button
	self.m_backButton:addEventListener("tap",self)
	self.m_backButton.width,self.m_backButton.height = display.contentWidth/9,display.contentWidth/9
	self.m_backButton.anchorX,self.m_backButton.anchorY = 0,0
	self:insert(self.m_clickScreen,self.m_button,self.m_backButton) 							-- add to view
	self.m_reciever = nil 																		-- nothing listening for commands.
--	if not info.retro then 																		-- frame o non retro view
--		self.m_frame = display.newImage("images/viewframe.png",display.contentWidth/2,display.contentHeight/2)
--		self.m_frame.alpha = 0.6
--		self.m_frame.width, self.m_frame.height = display.contentWidth*1.07,display.contentHeight*1.07
--		self:insert(self.m_frame)
--	end
end 

--//	Tidy up

function FrontController:destructor(info)
	self.m_clickScreen:removeEventListener("tap",self) 											-- remove listeners
	self.m_button:removeEventListener("tap",self)
	self.m_backButton:removeEventListener("tap",self)
	self.m_clickScreen:removeSelf() 															-- remove display objects
	self.m_button:removeSelf()
	if self.m_frame ~= nil then self.m_frame:removeSelf() end
	self.m_receiver = nil  																		-- nil receiver reference.
end 

--//	Set the object to receive command messages
--//	@object 	[object]		Object with an 'onCommand' method.
--//	@return 	[object] 		self 

function FrontController:attach(object)
	self.m_receiver = object 
	return self 
end 

--// 	Handle messages 

function FrontController:tap(e)
	local message = ""
	if e.target == self.m_button then  															-- fire presses
		message = "fire"
	elseif e.target == self.m_backButton then 
		self:sendMessage("changelistener",{ name = "nextstate" }) 
	else 
		if e.x < display.contentWidth / 4 or e.x > display.contentWidth * 3/4 then 				-- left or right quarter
			message = "right" 																	-- return left or right
			if e.x < display.contentWidth/2 then message = "left" end 
		else 
			message = "back" 																	-- forward/backward
			if e.y < display.contentHeight * 2/3 then message = "forward" end 					-- top 2/3 is forward
		end 
	end
	if self.m_receiver ~= nil then self.m_receiver:onCommand(message) end 						-- activate onCommand if listening.
	return true 
end 

--- ************************************************************************************************************************************************************************
--																		Player Manager Class
--- ************************************************************************************************************************************************************************

local PlayerManager = Executive:createClass()

--//	Constructor
--//	@info 	[table] 		Constructor information - has maze member

function PlayerManager:constructor(info)
	self.m_maze = info.maze  																	-- Remember the maze
	self.m_rechargeTime = info.fireTime or 2000 												-- firing time.
	self.m_isDying = false 																		-- set when dying 
	self.m_lastFire = 0  																		-- time of last fire.
	self:tag("+changelistener")
end 

--//	Tidy up

function PlayerManager:destructor()
	self.m_maze = nil self.m_player = nil 
end 

--//	Attach a player to the player manager
--//	@player 	[object] 		Player object
--//	@return 	[object] 		Self

function PlayerManager:attach(player)
	self.m_player = player 
	return self 
end 

--//	Handle Messages

function PlayerManager:onMessage(sender,body)
	local location = self.m_player:getLocation()												-- get player location
	if body.name == "phantom" and body.x == location.x and body.y == location.y then  			-- phantom moved to our square ?
		self:sendMessage("enemy", { name = "stop"}) 											-- stop all enemy attacks
		self:die()
	end 
	if body.name == "nextstate" then 															-- message to go to next state
		print("Game over")
		--TODO Switch new state
	end

end 

--//	Kill the player 

function PlayerManager:die() 
	if self.m_isDying then return end 															-- can't die twice
	self.m_isDying = true  																		-- flag dying
	self:sendMessage("changelistener",{ name = "die" }) 										-- tell the listener to display the dying display.
	Game.e.audio:play("die")
end 

--//	Handle a command received from a FrontController
--//	@cmd 		[string] 		Command received

function PlayerManager:onCommand(cmd)
	if self.m_player == nil or self.m_isDying then return end 									-- nothing attached
	if cmd == "left" or cmd == "right" then  													-- handle left/right turns
		local turn = (cmd == "left") and 1 or 3 												-- turn anticlockwise.
		self.m_player:turn(turn)
	end
	if cmd == "forward" or cmd == "back" then  													-- handle forward/back
		local dm = (cmd == "forward") and 1 or -1 												-- add or subtract directions
		local pos = self.m_player:getLocation()
		local dir = self.m_player:getDirection()
		pos.x = pos.x + dir.dx * dm pos.y = pos.y + dir.dy * dm 								-- work new position
		local tile = self.m_maze:get(pos.x,pos.y) 												-- read tile
		if tile ~= Maze.WALL then  																-- if not wall
			if tile == Maze.TELEPORT then  														-- check for teleport
				self.m_player:teleport() 														-- this actually does it
				self:addLibraryObject("utils.particle","ShortEmitter",  						-- and this provides the SFX.
							{ emitter = "Teleport", time = 3000, x = display.contentWidth/2, y = display.contentHeight / 2})
				Game.e.audio:play("teleport")
			else 
				self.m_player:setLocation(pos) 													-- update player new position.
			end
		end
	end
	if cmd == "fire" then  																		-- firing.
		local time = system.getTimer() 															-- get current time
		if time > self.m_lastFire then  														-- allowed to fire yet ?
			self.m_lastFire = time + self.m_rechargeTime   										-- set next fire time
			Game.e.audio:play("shoot") 															-- play fire f/x

			local target = self:findTarget() 													-- find what was hit
			if target == nil then target = { distance = 8 } end 								-- nothing.
			self:sendMessage("missile",target) 													-- fire missile
		end 
	end 
end 

--//	See what a fired missile would hit
--//	@return 	[table]	containing target (enemy ref) and distance

function PlayerManager:findTarget() 
	local pos = self.m_player:getLocation() 													-- player location 
	local dir = self.m_player:getDirection() 													-- player direction
	local enemyTable = self:query("enemy") 														-- list of enemies
	local result = nil
	local range = 0 																			-- absolute maximum range
	repeat 
		pos.x = pos.x + dir.dx pos.y = pos.y + dir.dy  											-- next position.
		range = range + 1 																		-- bump distance.
		for _,ref in pairs(enemyTable.objects) do 												-- see if any enemies there
			if ref.x == pos.x and ref.y == pos.y then 											-- found a hit.
				result = { target = ref, distance = range} 										-- this is what's been hit.
			end 
		end
	until result ~= nil or range > 7 															-- until found or out of range.
	return result
end
--- ************************************************************************************************************************************************************************
--																				Create phantoms
--- ************************************************************************************************************************************************************************

local Phantom = Executive:createClass()

--//	Constructor

function Phantom:constructor(info)
	self.m_maze = info.maze 																	-- save maze, player, maximum hits.
	self.m_player = info.player 
	self.m_maxHits = info.maxHits or 3
	self.m_speed = info.speed or 5000 															-- save speed
	self:tag("+enemy")
	self:resetPhantom() 																		-- reset the phantom.
end

--//	Relocate the phantom somewhere in the maze a reasonable way from the player.

function Phantom:resetPhantom()
	self:killTimer() 																			-- kill any curren ttimer
	self.m_timerID = self:addRepeatingTimer(self.m_speed) 										-- add a timer to move it.
	self.m_hitsLeft = math.random(math.max(math.floor(self.m_maxHits/2),1), 					-- work out hits required to kill.
																		math.floor(self.m_maxHits))
	local dist = (self.m_maze.m_width+self.m_maze.m_height) / 2 * 0.65 							-- how far away the phantoms have to be
	local pos = self.m_maze:findCell(dist,self.m_player:getLocation()) 							-- find a position not too near
	self.x = pos.x self.y = pos.y 																-- copy it into the phantom position.
	self:sendMessage("changelistener", { name = "phantom",x = self.x, y = self.y })				-- view update
end 

--//	Messages sent to phantoms 

function Phantom:onMessage(sender,body)
	if body.name == "stop" then 																-- can be commanded to stop.
		self:killTimer()
	end
	if body.name == "shot" then  																-- has been shot.
		self.m_hitsLeft = self.m_hitsLeft - 1
		-- TODO: Bump Score and Kills
		if self.m_hitsLeft == 0 then 															-- if dead then 
			Game.e.audio:play("deadphantom")			
			self.m_maxHits = self.m_maxHits + 0.6 												-- increase hits
			print(self.m_speed)
			self.m_speed = math.max(1000,self.m_speed * 0.85) 									-- increase spead.
			self:resetPhantom() 																-- reset phantom
			print(self.m_speed)
		end
	end
end 

--//	Kill any current timer

function Phantom:killTimer()
	if self.m_timerID ~= nil then 
		self:removeTimer(self.m_timerID)
		self.m_timerID = nil 
	end 
end 

--//	Move the phantom on the timer 

function Phantom:onTimer(tag,timerID)
	local player = self.m_player:getLocation() 													-- where the player is
	local dx,dy dx = player.x - self.x dy = player.y - self.y 									-- offset to player
	if dx ~= 0 then dx = dx / math.abs(dx) end 													-- make -1,0,1 
	if dy ~= 0 then dy = dy / math.abs(dy) end 
	if self.m_maze:get(self.x+dx,self.y+dy) == Maze.WALL and math.random(1,20) == 1 then 		-- if can not move then just once in a while.
		if math.random(1,2) == 1 then dx = 0 else dy = 0 end  									-- randomly zero one of dx,dy
	end

	if self.m_maze:get(self.x+dx,self.y+dy) ~= Maze.WALL then 									-- if can move
		self.x = self.x + dx self.y = self.y + dy 												-- move to new position
	 	self:sendMessage("changelistener", { name = "phantom",x = self.x, y = self.y })			-- view update
	end		
end

--//	Get a phantom location
--//	@return 	[table]			x,y in a table

function Phantom:getLocation()
	return { x = self.x, y = self.y }
end 

--- ************************************************************************************************************************************************************************
--//															Distance Monitoring Object
--- ************************************************************************************************************************************************************************

local PhantomMonitor = Executive:createClass() 

--// 	Create a new phantom monitor

function PhantomMonitor:constructor()
	self:addSingleTimer(1000)
end 

--//	Tidy up

function PhantomMonitor:destructor()
	self.m_player = nil 
end 

--//	Attach a player to the monitor
--//	@player 	[table] 		Player to attach

function PhantomMonitor:attach(player)
	self.m_player = player 
end 

--//	Handle phantom timer events - work out the nearest, and if not on top or too far away make breathy sound and refire at end
--//	otherwise refire after 1 second.

function PhantomMonitor:onTimer(deltaTime,deltaMillis,current)
	local phantoms = self:query("enemy") 														-- find all baddies
	if phantoms.count == 0 or self.m_player == nil then self:addSingleTimer(1000) return end 	-- if no phantoms or no player, fire again in 1 second.
	local nearest = 999999 																		-- initial distance
	local p = self.m_player:getLocation() 														-- player position
	for _,ref in pairs(phantoms.objects) do 													-- scan them all
		local p1 = ref:getLocation() 															-- get location 
		local dist = math.sqrt((p.x-p1.x)*(p.x-p1.x)+(p.y-p1.y)*(p.y-p1.y)) 					-- get distance
		nearest = math.min(dist,nearest)
	end 
	local breatheTime = math.max(0.3+nearest/4) 												-- how long the
	if nearest == 0 or breatheTime > 2.1 then self:addSingleTimer(1000)  return end 			-- right on top, or too long, fire again in 1 second.
	Game.e.audio:play("pulse") 																	-- play the breathy sound
	self:addSingleTimer(breatheTime * 1000) 													-- fire after the breathy sound
end

--- ************************************************************************************************************************************************************************
--														Missile View. Responsible for missile animation
--- ************************************************************************************************************************************************************************

local MissileView = Executive:createClass()

--// 	Create it

function MissileView:constructor(info)
	self.m_missile = display.newCircle(display.contentWidth/2,display.contentHeight/2,			-- missile graphic
																			display.contentHeight*0.44)
	self.m_missile:setFillColor(0,1,1) 															-- cyan
	self:insert(self.m_missile) 																-- add to executive group
	self.m_missile.alpha = 0 																	-- can't be seen
	self.m_missile.fill.effect = "filter.dissolve" 												-- dissolve effect
	self.m_missile.fill.effect.threshold = 0.6
	self:tag("missile") 																		-- tag as a missile.
end 

--//	Handle messages - two entiries, distance, how far in squares, and target, the shot object.

function MissileView:onMessage(sender,message)
	self.m_missile.alpha = 1 																	-- visible and to front
	self.m_missile:toFront()
	self.m_missile.xScale,self.m_missile.yScale = 1,1 											-- default size
	local scale = 0.6 / (message.distance+1) 													-- final size
	transition.to(self.m_missile, { time = 100*message.distance,xScale = scale,yScale = scale, 	-- trnsition it, and hide when finished
				onComplete = function() self.m_missile.alpha = 0 end })
	if message.target ~= nil then 
		self:sendMessage(message.target,{ name = "shot" },100*message.distance) 				-- also when finished, tell target it has been shot, if in range.
	end
end 

--//	Tidy up.

function MissileView:destructor()
	self.m_missile:removeSelf()
end 

--- ************************************************************************************************************************************************************************
--- ************************************************************************************************************************************************************************

local MainGameFactory = ExecutiveFactory:new()

function MainGameFactory:preOpen(info,eData)
	local executive = self:getExecutive() 														-- get the executive
	local maze = executive:addLibraryObject("classes.maze") 									-- add a maze object

	local view = "ModernViewRender" if eData.retro then view = "RetroViewRender" end 			-- figure out retro or modern view
	executive:addLibraryObject("classes.maprender"):name("map2Drender") 						-- create renderers
	executive:addLibraryObject("classes.viewrender",view):name("map3Drender")

	local player = executive:addLibraryObject("classes.player", { maze = maze }) 				-- add a player

	maze:add(1,Maze.TELEPORT,player:getLocation(),5)  											-- add a teleport, at least 5 units from the player.

	local manager = PlayerManager:new(executive, { maze = maze,fireTime = eData.fireTime }):attach(player) 				-- this object accepts commands and manipulates the player
	FrontController:new(executive, { retro = eData.retro }):attach(manager) 					-- this handles input which is passed to the manager
	FrontView:new(executive,{ maze = maze}):attach(player) 										-- add a 3D projection view, following the player.
	MapView:new(executive,{ maze = maze }):attach(player) 										-- add a map view, following the player
	MissileView:new(executive)
	for i = 1, eData.phantomCount or 14 do  													-- add the bad guys
		Phantom:new(executive, { maze = maze, player = player, speed = eData.phantomSpeed, maxHits = eData.phantomHits })
	end
	PhantomMonitor:new(executive):attach(player)												-- monitor enemy distances and make breathy sounds.
end

math.randomseed(42)
Game:addLibraryObject("utils.audio", { sounds = { "pulse","shoot","teleport","die","deadphantom" }} )
Game:addState("play",MainGameFactory:new(),{ endGame = { target = "play" }})
Game:start("play") --, { retro = false, phantomCount = 14, phantomSpeed = 3000, phantomHits = 3, fireTime = 2000 })

--[[

	Scoring 
		
	Phantom 
	  		- can actually run through phantoms .... (might actually allow this)

"they would be extremely sticky to get free form speedily
--]]
