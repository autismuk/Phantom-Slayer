--- ************************************************************************************************************************************************************************
--- ************************************************************************************************************************************************************************
---
---				Name : 		maze.lua
---				Purpose :	Maze class for Phatom Slayer
---				Created:	23rd June 2014
---				Author:		Paul Robson (paul@robsons.org.uk)
---				License:	MIT
---
--- ************************************************************************************************************************************************************************
--- ************************************************************************************************************************************************************************

-- Standard OOP (with Constructor parameters added.)
_G.Base =  _G.Base or { new = function(s,...) local o = { } setmetatable(o,s) s.__index = s o:initialise(...) return o end, initialise = function() end }

--- ************************************************************************************************************************************************************************
--																					Maze Class
--- ************************************************************************************************************************************************************************

local Maze = Base:new()

Maze.OPEN = 0  																					-- constants used in the Maze to represent solid things.
Maze.WALL = 1
Maze.TELEPORT = 2
																								-- (not actually put on the map !)
--//	Initialise and create maze
--//	@info 	[table]		constructor information.

function Maze:constructor(info) 
	local width,height,fillLevel
	width = info.width height = info.height fillLevel = info.fillLevel 							-- get constructor parameters.
	self.m_width = width or 20																	-- store width and self.m_height.
	self.m_height = height or 20
	self.m_map = {} 																			-- map. 0 = open, 1 = wall, 2 = compass, 3 = map, 4 = teleport
	fillLevel = fillLevel or 0.42 																-- proportion of walls required, max
	local iter  = 0 
	while self:getFillRatio() > fillLevel and iter < 500 do 									-- until filled or too many iterations
		self:addPart() 																			-- add a corridor
		iter = iter + 1
	end
end 

--//	Read cell x,y
--//	@x 	[number] 		horizontal position
--//	@y 	[number]		vertical position
--//	@return [number]	contents of the cell.

function Maze:get(x,y)
	return self.m_map[self:index(x,y)] or Maze.WALL 											-- default is wall.
end 

--//	Write to cell x,y
--//	@x 	[number] 		horizontal position
--//	@y 	[number]		vertical position
--//	@tile [number]		new contents of the cell.

function Maze:put(x,y,tile)
	if tile == Maze.WALL then tile = nil end 													-- keeps it as thin as possible.
	self.m_map[self:index(x,y)] = tile 
end 

--//	Convert an x,y coordinate pair to a single index into the maze map.
--//	@x 	[number] 		horizontal position
--//	@y 	[number]		vertical position
--//	@return [number] 	index for that position

function Maze:index(x,y) 
	x = (x + self.m_width * 100) % self.m_width  												-- maze wraps around
	y = (y + self.m_height * 100) % self.m_height 
	return x + y * 1000																			-- convert it to a single number representing the cell.
end 

--//	Put objects in the maze map, a minimum distance from the player.
--//	@quantity 	[number]	Number of items
--//	@tile 		[number]	tile ID
--//	@player 	[player] 	player object
--//	@distance 	[number]	how far  away does it have to be.

function Maze:add(quantity,tile,player,distance)
	for i = 1,quantity do 																		-- for the given number of objects
		local cell = self:findCell(distance,player) 											-- find a space away from the player
		self:put(cell.x,cell.y,tile) 															-- put the tile there.
	end 
end

--//	Find an empty cell and minimum distance from the position.
--//	@minDistance 	[number]	how far  away does it have to be.
--//	@fromCoord 	 	[table]		x,y location of the position.
--//	@return 		[table] 	x,y position of empty cell.

function Maze:findCell(minDistance,fromCoord) 
	local cell,dist 																			-- find a cell not that close to a given coordinate
	repeat 
		cell = { x = math.random(0,self.m_width-1), y = math.random(0,self.m_height-1) }  		-- create a new cell
		dist = math.sqrt(math.pow(cell.x-fromCoord.x,2) + math.pow(cell.y-fromCoord.y,2)) 		-- calculate the distance.
	until self:get(cell.x,cell.y) == Maze.OPEN and dist > minDistance 							-- keep going until both open and not too near to the object
	return cell 
end 

--//	Add a single corridor to the maze, as far as it is allowable without creating a 2x2 open space in the map.

function Maze:addPart()
	local x,y,size,dx,dy 
	x = math.random(0,self.m_width-1) y = math.random(0,self.m_height-1)  						-- start point.
	dx = math.random(0,1)*2-1 dy = 0 															-- direction.
	if math.random(0,1) == 0 then dy = dx dx = 0 end 											-- shift from vertical to horizontal.
	size = math.random(3,math.floor(math.max(self.m_width,self.m_height)/2)) 					-- length of corridor
	repeat 
		local ok = true 
		self:put(x,y,Maze.OPEN) 																-- open it up
		ok = ok and self:checkOpenSquare(x,y) and self:checkOpenSquare(x-1,y) 					-- check open corridor is not created by this.
		ok = ok and self:checkOpenSquare(x,y-1) and self:checkOpenSquare(x-1,y-1) 				-- cannot have 'open rooms' - a 2x2 square which is open.
		if not ok then self:put(x,y,Maze.WALL) end 												-- if failed, then close it again.
		x = x + dx y = y + dy 																	-- move to next.
		size = size - 1 																		-- decrement size
	until size == 0 or (not ok) 																-- until done the lot, or failed.
end 

--//	Check to see if 4 squares x,y .. x+1,y+1 are all open, which indicates an invalid maze
--//	@x 	[number] 		horizontal position
--//	@y 	[number]		vertical position
--//	@return [boolean] 	true if at least one is not open.

function Maze:checkOpenSquare(x,y)
	return self:get(x,y) ~= Maze.OPEN or self:get(x,y+1) ~= Maze.OPEN 							-- check four squares at x,y
					or self:get(x+1,y) ~= Maze.OPEN or self:get(x+1,y+1) ~= Maze.OPEN 			-- this open room isn't allowed.
end 

--//	Dump maze to console in a texty fashion.

function Maze:print()
	local parts = {}
	parts[Maze.OPEN] = " " parts[Maze.WALL] = "X" parts[Maze.TELEPORT] = "t" 
	print(string.rep("#",self.m_width+2))
	for y = 0,self.m_height-1 do 
		local s = ""
		for x = 0,self.m_width-1 do 
			s = s .. parts[self:get(x,y)]
		end 
		print("#"..s.."#")
	end
	print(string.rep("#",self.m_width+2))
end 

--//	Work out the ration of Wall to Open for the maze
--//	@return [number] 	wall proportion.

function Maze:getFillRatio() 
	local count = 0
	for y = 0,self.m_height-1 do  																-- scan the maze
		for x = 0,self.m_width-1 do 
			if self:get(x,y) == Maze.WALL then count = count + 1 end 							-- count the walls.
		end 
	end
	return count / self.m_height / self.m_width 												-- wall ratio.
end

return Maze

