--- ************************************************************************************************************************************************************************
--- ************************************************************************************************************************************************************************
---
---				Name : 		maprender.lua
---				Purpose :	Map Renderer class for Phatom Slayer
---				Created:	23rd June 2014
---				Author:		Paul Robson (paul@robsons.org.uk)
---				License:	MIT
---
--- ************************************************************************************************************************************************************************
--- ************************************************************************************************************************************************************************

-- Standard OOP (with Constructor parameters added.)
_G.Base =  _G.Base or { new = function(s,...) local o = { } setmetatable(o,s) s.__index = s o:initialise(...) return o end, initialise = function() end }

--- ************************************************************************************************************************************************************************
--																			Map Render Class
--- ************************************************************************************************************************************************************************

local MapRender = Base:new()

MapRender.PS_PLAYER = -1 																		-- used in the map routine only as the tile where the player is.

--//	Create a display object with a rendering of the map on it
--//	@maze 		[Maze]					Maze to render
--//	@player 	[Player]				Location of player (optional)
--//	@phantoms 	[Table]					Array of phantoms
--//	@width 		[number]				Width of display object (optional)
--//	@height 	[number]				Height of display object (optional)
--//	@return 	[displayObject]			Rendering of the maze map.

function MapRender:render(maze,player,phantoms,width,height)
	width = width or 300 height = height or width 												-- default size.
	local group = display.newGroup()															-- everything in this group.
	local frame = display.newImage(group,"images/frame.png",0,0) 								-- load the map frame in.
	frame.anchorX,frame.anchorY = 0,0
	frame.width = width frame.height = height
	local xo = width/17  																		-- work out frame edge sizes
	local yo = height/11
	width = width - xo * 2 height = height - yo * 2 											-- adjust width and height to fit.
	local cw = width/maze.m_width 																-- cell size
	local ch = height/maze.m_height
	local r = display.newRect(xo,yo,width,height) 												-- background rectangle.
	local playerPos = player:getLocation()
	r.anchorX,r.anchorY = 0,0
	r:setFillColor(1,1,0)
	group:insert(r)
	for y = 0,maze.m_height-1 do 																-- scan the maze
		for x = 0,maze.m_width-1 do 
			local tile = maze:get(x,y) 															-- get tile from map.
			if player ~= nil and x == playerPos.x and y == playerPos.y then 					-- if player at square, display that psuedo-tile 
				tile = MapRender.PS_PLAYER 
			end 
			if tile ~= Maze.OPEN then 															-- non space tile.
				r = self:getCellObject(tile) 													-- get representing object
				if r ~= nil then 																-- if something was returned
					r.x,r.y = xo+x*cw+cw/2,yo+y*ch+ch/2 												-- position and scale it
					r.width,r.height = cw,ch
					group:insert(r) 															-- insert into group
					if tile == MapRender.PS_PLAYER then 										-- player is a directional object so rotate it 
						local d = player:getDirection() 										-- get the direction.
						if d.dx ~= 0 then r.rotation = (1-d.dx) * 90  							-- rotate the object accordingly.
						else r.rotation = (d.dy+1) * 90 - 90 end
					end
				end
			end
		end 
	end
	frame:toFront()
	return group
end 

--//	Get the display object for a given tile (includes MapRender.PS_PLAYER). Doesn't matter what size it is as it will be scaled 
--//	to fit.
--//	@tile 	[number]			Tile to render
--//	@return [displayObject]		Corona Display Object

function MapRender:getCellObject(tile)
	local r 
	if tile == Maze.WALL then   																-- wall yellow square
		r = display.newRect(0,0,32,32)
		r:setFillColor( 0,0,1 )
	end
	if tile == Maze.TELEPORT then  																-- teleport red outline square
		r = display.newRect(0,0,10,10)
		r:setFillColor( 0,0.5,0 )
	end
	if tile == MapRender.PS_PLAYER then  														-- player  green triangle.
		r = display.newPolygon(0,0,{ 0,0, 40,0, 40,20, 60,20, 60,40, 40,40, 40,60, 0,60, 0,40, 20,40, 20,20, 0,20 })
		r:setFillColor(1,0,0)
	end 
	return r
end 

return MapRender