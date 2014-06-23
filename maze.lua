--- ************************************************************************************************************************************************************************
--- ************************************************************************************************************************************************************************
---
---				Name : 		maze.lua
---				Purpose :	Maze object for Phatom Slayer
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
Maze.COMPASS = 2
Maze.MAP = 3
Maze.TELEPORT = 4
Maze.PS_PLAYER = -1 																			-- used in the map routine only as the tile where the player is.
																								-- (not actually put on the map !)

function Maze:initialise(width,height,fillLevel) 
	if width == nil then return end 															-- being used as a subclass ?
	self.m_width = width or 20																	-- store width and self.m_height.
	self.m_height = height or 20
	self.m_map = {} 																			-- map. 0 = open, 1 = wall, 2 = compass, 3 = map, 4 = teleport, +100 = phantom
	fillLevel = fillLevel or 0.42 																-- proportion of walls required, max
	local iter  = 0 
	while self:getFillRatio() > fillLevel and iter < 500 do 									-- until filled or too many iterations
		self:addPart() 																			-- add a corridor
		iter = iter + 1
	end
	self.m_playerSpace = math.max(5,math.max(self.m_width,self.m_height)/2) 					-- how far away do things have to be ?
	self.m_player = self:findCell(0,{ x = -100,y = -100 }) 										-- get the player, fake the minimum distance.
	local maps = math.floor(math.max(1,self.m_width * self.m_height / 30))						-- number of maps and compasses
	self:add(maps,Maze.COMPASS)
	self:add(maps,Maze.MAP)
	self:add(1,Maze.TELEPORT) 																	-- add a teleport.
	repeat  																					-- face player away from a wall.
		self.m_player.dx = math.random(0,1) * 2 - 1 self.m_player.dy = 0 						-- work out a random direction for player
		if math.random(0,1) == 0 then self.m_player.dy = self.m_player.dx self.m_player.dx = 0 end 
	until self:get(self.m_player.x + self.m_player.dx,self.m_player.y + self.m_player.dy) == Maze.OPEN
end 

function Maze:get(x,y)
	return self.m_map[self:index(x,y)] or Maze.WALL 											-- default is wall.
end 

function Maze:put(x,y,tile)
	if tile == Maze.WALL then tile = nil end 													-- keeps it as thin as possible.
	self.m_map[self:index(x,y)] = tile 
end 

function Maze:index(x,y) 
	x = (x + self.m_width * 100) % self.m_width  												-- maze wraps around
	y = (y + self.m_height * 100) % self.m_height 
	return x + y * 1000																			-- convert it to a single number representing the cell.
end 

function Maze:add(quantity,tile)
	for i = 1,quantity do 																		-- for the given number of objects
		local cell = self:findCell(self.m_playerSpace,self.m_player) 							-- find a space away from the player
		self:put(cell.x,cell.y,tile) 															-- put the tile there.
	end 
end

function Maze:findCell(minDistance,fromCoord) 
	local cell,dist 																			-- find a cell not that close to a given coordinate
	repeat 
		cell = { x = math.random(0,self.m_width-1), y = math.random(0,self.m_height-1) }  		-- create a new cell
		dist = math.sqrt(math.pow(cell.x-fromCoord.x,2) + math.pow(cell.y-fromCoord.y,2)) 		-- calculate the distance.
	until self:get(cell.x,cell.y) == Maze.OPEN and dist > minDistance 							-- keep going until both open and not too near to the object
	return cell 
end 

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

function Maze:checkOpenSquare(x,y)
	return self:get(x,y) ~= Maze.OPEN or self:get(x,y+1) ~= Maze.OPEN 							-- check four squares at x,y
					or self:get(x+1,y) ~= Maze.OPEN or self:get(x+1,y+1) ~= Maze.OPEN 			-- this open room isn't allowed.
end 

function Maze:print()
	local parts = {}
	parts[Maze.OPEN] = " " parts[Maze.WALL] = "X" parts[Maze.COMPASS] = "c" 
	parts[Maze.MAP] = "m" parts[Maze.TELEPORT] = "t" 
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

function Maze:getFillRatio() 
	local count = 0
	for y = 0,self.m_height-1 do  																-- scan the maze
		for x = 0,self.m_width-1 do 
			if self:get(x,y) == Maze.WALL then count = count + 1 end 							-- count the walls.
		end 
	end
	return count / self.m_height / self.m_width 												-- wall ratio.
end

function Maze:getMapDisplayObject(width,height)
	width = width or 300 height = height or 300 												-- default size.
	local group = display.newGroup()															-- everything in this group.
	local cw = width/self.m_width 																-- cell size
	local ch = height/self.m_height
	local r = display.newRect(0,0,width,height) 												-- background rectangle.
	r.anchorX,r.anchorY = 0,0
	r:setFillColor(0,0,0.5)
	group:insert(r)
	for y = 0,self.m_height-1 do 																-- scan the maze
		for x = 0,self.m_width-1 do 
			local tile = self:get(x,y) % 100 													-- get tile, forget any phantoms there.
			if x == self.m_player.x and y == self.m_player.y then tile = Maze.PS_PLAYER end 	-- if player at square, display that psuedo-tile 
			if tile ~= Maze.OPEN then 															-- non space tile.
				r = self:getCellObject(tile) 													-- get representing object
				if r ~= nil then 																-- if something was returned
					r.x,r.y = x*cw+cw/2,y*ch+ch/2 												-- position and scale it
					r.width,r.height = ch,ch
					group:insert(r) 															-- insert into group
				end
			end
		end 
	end
	return group
end 

function Maze:getCellObject(tile)
	local r 
	if tile == Maze.WALL then   																-- wall (1) yellow square
		r = display.newRect(0,0,32,32)
		r:setFillColor( 1,1,0 )
	end
	if tile == Maze.TELEPORT then  																-- teleport (4) red outline square
		r = display.newRect(0,0,10,10)
		r:setFillColor( 0,0,0,0 )
		r:setStrokeColor(1,0,0)
		r.strokeWidth = 3
	end
	if tile == Maze.PS_PLAYER then  															-- player (-1) green triangle.
		r = display.newCircle(0,0,10)
		r:setFillColor(0,1,0)
	end 
	return r
end 

math.randomseed(42)
m = Maze:new(20,20)
m:print()
print(m:getFillRatio())
c = m:getMapDisplayObject()
c.x,c.y = 10,110