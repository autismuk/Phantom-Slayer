display.setStatusBar(display.HiddenStatusBar)

local ExecutiveFactory = require("system.game")
local Executive = require("system.executive")
local Maze = require("classes.maze")

local ViewObjectBase = Executive:createClass()

function ViewObjectBase:constructor(info)
	self.m_player = nil 																		-- current player view is watching, currently nothing.
	self.m_xView = nil self.m_yView = nil self.m_direction = nil 								-- x, y and direction		
	self.m_maze = info.maze 																	-- maze in
	self:tag("update") 																			-- updateable object 
	self.m_object = nil 																		-- current display object
end 

function ViewObjectBase:destructor()
	if self.m_object ~= nil then self.m_object:removeSelf() end 
	self.m_object = nil 
end 

function ViewObjectBase:attach(player)
	self.m_player = player 																		-- store player.
	self.m_xView = nil 																			-- this invalidates 'current view' position, so it will be redrawn.
	return(self)
end 

function ViewObjectBase:onUpdate()
	if self.m_player == nil then return end 													-- exit if no player attached.
	local nDirection = 1 - self.m_player.dx  													-- convert to 0,1,2,3
	if self.m_player.dy ~= 0 then nDirection = self.m_player.dy + 2 end 		
	if self.m_player.x ~= self.m_xView or self.m_player.y ~= self.m_yView or 
													self.m_direction ~= nDirection then 
		local posChange = self.m_player.x ~= self.m_xView or self.m_player.y ~= self.m_yView 	-- has position changed ?													
		self.m_xView = self.m_player.x self.m_yView = self.m_player.y 							-- update player position and direction.
		local turn = 0 																			-- work out turning.
		if self.m_direction ~= nil then turn = (nDirection - self.m_direction + 4) % 4 end
		self.m_direction = nDirection
		self:updateView(self.m_player,turn,posChange)
	end
end 

local MapView = ViewObjectBase:new()

function MapView:updateView(player,turn,posChange)
	if self.m_object ~= nil then self.m_object:removeSelf() end									-- remove old object 
	local renderer = self:getExecutive().e.map2Drender 											-- render it.
	local m = renderer:render(self.m_maze,player,{},display.contentWidth/3,display.contentHeight/3)
	m.x = display.contentWidth*2/3-10 m.y = 10 													-- position it
	m.alpha = 0.7 																				-- slightly transparent
	m:toFront() 																				-- bring it to the front.
	self.m_object = m
end 

local FrontView = ViewObjectBase:new()

function FrontView:updateView(player,turn,posChange)
	local renderer = self:getExecutive().e.map3Drender 											-- render it.
	local m = renderer:render(self.m_maze,player,{},display.contentWidth,display.contentHeight)
	if self.m_object ~= nil then self.m_object:toBack() end
	m:toBack() 																					-- bring it to the front.

	if posChange or (turn ~= 1 and turn ~= 3) or self.m_object == nil then 						-- is it a positional change, or a 180 degree turn, or first
		if self.m_object ~= nil then self.m_object:removeSelf() end								-- remove old object 
		self.m_object = m 
	else 	
		local tTime = 250
		if turn == 1 then 
			m.x = display.contentWidth
			transition.to(m,{ time = tTime, x = 0})
			transition.to(self.m_object,{ time = tTime, x = -display.contentWidth, onComplete = function(obj) obj:removeSelf() end})
			self.m_object = m
		else 
			m.x = -display.contentWidth
			transition.to(m,{ time = tTime, x = 0})
			transition.to(self.m_object,{ time = tTime, x = -isplay.contentWidth, onComplete = function(obj) obj:removeSelf() end})
			self.m_object = m
		end 
	end

end 

local xplayer = {}

local MainGameFactory = ExecutiveFactory:new()

function MainGameFactory:preOpen(info)
	math.randomseed(42)
	local executive = self:getExecutive()
	executive:addLibraryObject("classes.maze"):name("maze")
	executive:addLibraryObject("classes.maprender"):name("map2Drender")
	executive:addLibraryObject("classes.viewrender","ModernViewRender"):name("map3Drender")

	xplayer = executive:addLibraryObject("classes.player", { maze = executive.e.maze }):name("player")
	executive.e.maze:add(1,Maze.TELEPORT,executive.e.player:getLocation(),5) 

	--executive.e.maze:put(executive.e.player.x,executive.e.player.y-3,Maze.TELEPORT)

	fakePhantom = {}
	fakePhantom[14] = { x = executive.e.player.x,y = executive.e.player.y - 2 }

	executive:insert(display.newRect(0,0,10,10))
	--	executive:addLibraryObject("classes.maprender"):name("map2Drender")	
	MapView:new(executive,{ maze = executive.e.maze}):attach(executive.e.player)
	FrontView:new(executive,{ maze = executive.e.maze}):attach(executive.e.player)

	-- w = DisplayRenderer:new(executive,{ maze = executive.e.maze, player = executive.e.player })
	-- MapRenderer:new(executive,{ maze = executive.e.maze, player = executive.e.player })

	--fakePhantom[1] = { x = player.x,y = player.y - 1 }
end

Game:addState("play",MainGameFactory:new(),{ endGame = { target = "play" }})
Game:start("play")

local c = 0
Runtime:addEventListener("enterFrame", function(e)
	c = c + 1
	if c % 40 == 0 then 
		--local t = xplayer:getTurnOffset(1)
		--xplayer.dx = t.dx xplayer.dy = t.dy
		xplayer.y = xplayer.y - 1
	end
end)