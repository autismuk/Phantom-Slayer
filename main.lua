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
	self:tag("update") 																			-- updateable object 
	self.m_object = nil 																		-- current display object
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
	local m = renderer:render(self.m_maze,player,{},display.contentWidth/3,display.contentHeight/3)
	m.x = display.contentWidth*2/3-20 m.y = 20 													-- position it
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

--- ************************************************************************************************************************************************************************
--																		Controller/Front Frame
--- ************************************************************************************************************************************************************************

local FrontController = Executive:createClass()

--// 	Create front display - click area, fire button and frame.

function FrontController:constructor(info) 
	self.m_clickScreen = display.newRect(0,0,display.contentWidth,display.contentHeight) 		-- nearly transparent screen to click on.
	self.m_clickScreen.anchorX,self.m_clickScreen.anchorY = 0,0 self.m_clickScreen.alpha = 0.01
	self.m_button = display.newImage("images/button.png",										-- fire button
											display.contentWidth-10,display.contentHeight-10)
	self.m_button.anchorX,self.m_button.anchorY = 1,1 
	self.m_button.width,self.m_button.height = display.contentWidth/5,display.contentWidth/5
	self:insert(self.m_clickScreen,self.m_button) 												-- add to view
	if not info.retro then 																		-- frame o non retro view
		self.m_frame = display.newImage("images/viewframe.png",display.contentWidth/2,display.contentHeight/2)
		self.m_frame.alpha = 0.6
		self.m_frame.width, self.m_frame.height = display.contentWidth*1.07,display.contentHeight*1.07
		self:insert(self.m_frame)
	end
	self.m_clickScreen:addEventListener("tap",self) 											-- add tap listeners
	self.m_button:addEventListener("tap",self) 
	self.m_reciever = nil 																		-- nothing listening for commands.
end 

--//	Tidy up

function FrontController:destructor(info)
	self.m_clickScreen:removeEventListener("tap",self) 											-- remove listeners
	self.m_button:removeEventListener("tap",self)
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

function PlayerManager:constructor(info)
	self.m_maze = info.maze 
end 

function PlayerManager:destructor()
	self.m_maze = nil self.m_player = nil 
end 

function PlayerManager:attach(player)
	self.m_player = player 
	return self 
end 

function PlayerManager:onCommand(cmd)
	if self.m_player == nil then return end
	if cmd == "left" or cmd == "right" then 
		local turn = (cmd == "left") and 1 or 3
		self.m_player:turn(turn)
	end
	if cmd == "forward" or cmd == "back" then 
		local dm = (cmd == "forward") and 1 or -1
		local pos = self.m_player:getLocation()
		local dir = self.m_player:getDirection()
		pos.x = pos.x + dir.dx * dm pos.y = pos.y + dir.dy * dm
		local tile = self.m_maze:get(pos.x,pos.y)
		if tile ~= Maze.WALL then 
			if tile == Maze.TELEPORT then 
				self.m_player:teleport()
				self:addLibraryObject("utils.particle","ShortEmitter", 
							{ emitter = "Teleport", time = 3000, x = display.contentWidth/2, y = display.contentHeight / 2})
			else 
				self.m_player:setLocation(pos)
			end
		end
	end
end 

--- ************************************************************************************************************************************************************************
--- ************************************************************************************************************************************************************************

local MainGameFactory = ExecutiveFactory:new()

function MainGameFactory:preOpen(info)
	math.randomseed(42)
	local executive = self:getExecutive()
	local maze = executive:addLibraryObject("classes.maze")

	local view = "ModernViewRender" if info.retro then view = "RetroViewRender" end
	executive:addLibraryObject("classes.maprender"):name("map2Drender")
	executive:addLibraryObject("classes.viewrender",view):name("map3Drender")

	local player = executive:addLibraryObject("classes.player", { maze = maze })

	maze:add(1,Maze.TELEPORT,player:getLocation(),5) 

	maze:put(player.x,player.y-4,Maze.TELEPORT)

	MapView:new(executive,{ maze = maze, time = 99999999 }):attach(player)
	local manager = PlayerManager:new(executive, { maze = maze }):attach(player)
	FrontController:new(executive, { retro = info.retro }):attach(manager)
	FrontView:new(executive,{ maze = maze}):attach(player)

end

Game:addState("play",MainGameFactory:new({ retro = false }),{ endGame = { target = "play" }})
Game:start("play")

--[[
	
	MapView - auto disappear (time parameter) self destructs, can't update while closing.
	Controller - manipulates an attached player, fire delay
	Phantom - object that moves about, queried by view, check collision with player(s).
	Missile - fired by current player (instigted by controller), hides if player turns.

--]]
