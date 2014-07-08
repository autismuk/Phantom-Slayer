--- ************************************************************************************************************************************************************************
--- ************************************************************************************************************************************************************************
---
---				Name : 		player.lua
---				Purpose :	Player Class for Phatom Slayer
---				Created:	23rd June 2014
---				Author:		Paul Robson (paul@robsons.org.uk)
---				License:	MIT
---
--- ************************************************************************************************************************************************************************
--- ************************************************************************************************************************************************************************

-- Standard OOP (with Constructor parameters added.)
_G.Base =  _G.Base or { new = function(s,...) local o = { } setmetatable(o,s) s.__index = s o:initialise(...) return o end, initialise = function() end }

local Maze = require("classes.maze")

--- ************************************************************************************************************************************************************************
--																	Player Class
--- ************************************************************************************************************************************************************************

local Player = Base:new()

--//	Initialise a player, putting them in the maze.
--//	@maze 	[Maze] 			maze instance.

function Player:constructor(info)
	self.m_maze = info.maze
	assert(self.m_maze ~= nil,"No maze provided for player")
	local p = self.m_maze:findCell(0,{ x = 0,y = 0 }) 											-- get the player start point, fake the minimum distance.
	self.x = p.x self.y = p.y
	repeat  																					-- face player away from a wall.
		self.dx = math.random(0,1) * 2 - 1 self.dy = 0 											-- work out a random direction for player
		if math.random(0,1) == 0 then self.dy = self.dx self.dx = 0 end 
	until self.m_maze:get(self.x + self.dx,self.y + self.dy) == Maze.OPEN
	self.xStart = self.x self.yStart = self.y self.dxStart = self.dx self.dyStart = self.dy		-- remember where we start.
	self:tag("+player") 																		-- tag it as a player.
end

--//	Get player's location
--//	@return [table] 	x,y coordinates

function Player:getLocation()
	return { x = self.x, y = self.y }
end

--//	Set player's location
--//	@pos 	[table]		x,y coordinates

function Player:setLocation(pos) 
	self.x = (pos.x + self.m_maze.m_width) % self.m_maze.m_width
	self.y = (pos.y + self.m_maze.m_height) % self.m_maze.m_height
end 

--//	Get player's direction.
--//	@return [table]		delta x,delta y values 

function Player:getDirection()
	return { dx = self.dx, dy = self.dy }
end 

--//	Teleport back to the player's start point.

function Player:teleport()
	self.x = self.xStart self.y = self.yStart self.dx = self.dxStart self.dy = self.dyStart
end 

--//	Get player's direction if they turn.
--//	@turn 	[number]	number of 90 degree turns anti-clockwise (e.g. turning left, 1 is left, 3 is effectively right)
--//	@return [table]		delta x,delta y values 

function Player:getTurnOffset(turn) 
	turn = (turn + 100) % 4
	local result = { dx = self.dx, dy = self.dy }
	for i = 1,turn do 
		if result.dx == 0 then result.dx = result.dy result.dy = 0 
		else result.dy = -result.dx result.dx = 0 end 
	end
	return result 
end 

--//	Rotate the player
--//	@turn 	[number]		90 degree clockwise rotations.

function Player:turn(turn)
	local newd = self:getTurnOffset(turn)
	self.dx = newd.dx self.dy = newd.dy 
end 

return Player