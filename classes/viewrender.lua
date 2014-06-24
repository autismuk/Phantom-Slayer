--- ************************************************************************************************************************************************************************
--- ************************************************************************************************************************************************************************
---
---				Name : 		viewrender.lua
---				Purpose :	Faux 3D Renderer class for Phatom Slayer
---				Created:	24th June 2014
---				Author:		Paul Robson (paul@robsons.org.uk)
---				License:	MIT
---
--- ************************************************************************************************************************************************************************
--- ************************************************************************************************************************************************************************

-- Standard OOP (with Constructor parameters added.)
_G.Base =  _G.Base or { new = function(s,...) local o = { } setmetatable(o,s) s.__index = s o:initialise(...) return o end, initialise = function() end }

local ViewRender = Base:new()

--//	Create a display object with a rendering of the map on it
--//	@maze 		[Maze]					Maze to render
--//	@player 	[Player]				Location of player (optional)
--//	@phantoms 	[Table]					Array of phantoms
--//	@width 		[number]				Width of display object (optional)
--//	@height 	[number]				Height of display object (optional)
--//	@return 	[displayObject]			Rendering of the maze map.

function ViewRender:render(maze,player,phantoms,width,height)
	width = width or 300 height = height or (width * 3 / 4)										-- default size.
	self.m_width = width self.m_height = height 												-- save size.
	self.m_group = display.newGroup()															-- everything in this group.
	self:renderBackground(width,height,height * 0.52) 											-- draw the skybox
	local depth = 0 																			-- current drawing depth.
	local x = player.x  																		-- current square.
	local y = player.y

	while self:getDepthRect(depth) ~= nil and maze:get(x+player.dx,y+player.dy) ~= Maze.WALL do -- find out how far we can see.
		depth = depth + 1 
		x = x + player.dx y = y + player.dy 
	end 
	local visibleDepth = depth
	repeat 
		local rOuter = self:getDepthRect(depth) 												-- get the depth of the outer rectangle
		local rMiddle = self:getDepthRect(depth+0.5)
		local rInner = self:getDepthRect(depth+1)
		x = player.x + depth * player.dx y = player.y + depth * player.dy
		-- if rInner ~= nil then local r2 = display.newRect(self.m_group,rInner.x1,rInner.y1,rInner.width,rInner.height) r2:setFillColor(0,0,0,0) r2:setStrokeColor(0,0.4,0,0.5) r2.strokeWidth = 1 r2.anchorX,r2.anchorY = 0,0 end
		if rInner ~= nil then  
			self:renderWall({ rInner.x1,rInner.y2,rOuter.x1,rOuter.y2,rOuter.x2,rOuter.y2,rInner.x2,rInner.y2},"f")
			if depth > 0 then 
				for _,ref in ipairs(phantoms) do 
					if ref.x == x and ref.y == y then 
						self:renderPhantom(rMiddle)
					end 
				end 
			end			local tile = maze:get(x,y) 															-- get tile.
			if depth >= 0 and tile ~= Maze.WALL and tile ~= Maze.OPEN then  					-- if not first bit, and something is there that's drawaable.
				self:renderMazeObject(tile,rMiddle)
			end

			if maze:get(x + player.dx,y + player.dy) == Maze.WALL then 							-- wall in front.
				self:renderWall({ rInner.x1,rInner.y1,rInner.x1,rInner.y2,  					-- render central wall.
										rInner.x2,rInner.y2,rInner.x2,rInner.y1 },"c")				
			end

			local wall = { rOuter.x1,rOuter.y1,rOuter.x1,rOuter.y2, 							-- closed left wall
											rInner.x1,rInner.y2,rInner.x1,rInner.y1 }
			local dl = player:getTurnOffset(1)													-- offset to left cell.
			if maze:get(x+dl.dx,y+dl.dy) ~= Maze.WALL then 										-- if open, make wall square
				wall[2]=wall[8] wall[4]=wall[6] 
			end 
			self:renderWall(wall,"l")  															-- draw it.
			local wall = { rInner.x2,rInner.y1,rInner.x2,rInner.y2, 							--closed right wall
											rOuter.x2,rOuter.y2,rOuter.x2,rOuter.y1 }
			local dr = player:getTurnOffset(3)													-- offset to right cell
			if maze:get(x+dr.dx,y+dr.dy) ~= Maze.WALL then  									-- if open make square
				wall[8]=wall[2] wall[6]=wall[4] 
			end 	
			self:renderWall(wall,"r") 															-- draw it.
		end  
		depth = depth - 1 																		-- next depth
	until depth < 0  																			-- until out of range or we hit a wall.

	local r = self:getDepthRect(visibleDepth+1)  												-- this is the last depth drawn.
	while r == nil do r = self:getDepthRect(visibleDepth) visibleDepth = visibleDepth - 1 end
	return self.m_group
end 

--// 		Get the rectangle encompassing the view area (e.g. the wall in front) at a specific depth.
--//		@depth 		[number] 		Depth in squares into the screen.
--//		@return 	[table]			Rectangle x1,y1,x2,y2,width,height

function ViewRender:getDepthRect(depth) 
	if depth > 7 then return nil end 
	local vStep = self.m_height / 2.7
	local rect = { height = self.m_height - vStep * math.pow(depth - 0.3,0.5) }
	rect.width = rect.height * self.m_width / self.m_height
	if depth == 0 then rect = { width = self.m_width, height = self.m_height } end
	rect.x1 = self.m_width / 2 - rect.width / 2 rect.y1 = self.m_height / 2 - rect.height / 2
	rect.x2 = rect.x1 + rect.width rect.y2 = rect.y1 + rect.height
	return rect
end 

function ViewRender:renderBackground(width,height,skyHeight)
	local background = display.newRect(self.m_group,0,0,width,skyHeight) 						-- solid yellow background upper
	background.anchorX,background.anchorY = 0,0 background:setFillColor(1,1,0)
	local background = display.newRect(self.m_group,0,skyHeight,width,height-skyHeight) 		-- solid yellow background upper
	background.anchorX,background.anchorY = 0,0 background:setFillColor(1,1,0)
end 

function ViewRender:renderWall(path,type)
	local r = self:getWallImage(type)
	local isSolid = (r == nil)
	if isSolid then r = display.newRect(0,0,100,100) end
	r.width = 100 r.height = 100
	local p = r.path 
	p.x1,p.y1 = 0,0
	p.x2,p.y2 = path[3]-path[1],path[4]-path[2]-100
	p.x3,p.y3 = path[5]-path[1]-100,path[6]-path[2]-100
	p.x4,p.y4 = path[7]-path[1]-100,path[8]-path[2]
	self.m_group:insert(r)
	r.x,r.y = path[1],path[2]
	r.anchorX,r.anchorY = 0,0
	if isSolid then 
		r:setFillColor(0,0,1)
		if type == "f" then 
			r:setFillColor(0,0,0,0) 
			r:setStrokeColor(1,0,0) r.strokeWidth = 1 
		end
		if type ~= "c" and type ~= "f" then 
			local l 
			if type == "l" then l = display.newLine(path[5],path[6],path[7],path[8]) end
			if type == "r" then l = display.newLine(path[1],path[2],path[3],path[4]) end
			l:setStrokeColor(1,1,0)
			self.m_group:insert(l) 
		end
	end
end 

function ViewRender:getWallImage(type)
	return nil
end 

function ViewRender:renderMazeObject(tile,rDraw)
	if tile == Maze.TELEPORT then 
		local r = display.newCircle(rDraw.x1+rDraw.width/2,rDraw.y1+rDraw.height/2,32)
		r.width, r.height = rDraw.width*0.7,rDraw.height
		r.fill.effect = "filter.dissolve"
		r.fill.effect.threshold = 0.5
		r:setFillColor(0,1,0)
		self.m_group:insert(r)
	end 
end 

function ViewRender:renderPhantom(rDraw)
	local img = self:getPhantomImage()
	img.x,img.y = rDraw.x1+rDraw.width/2,rDraw.y1+rDraw.height/2
	self.m_group:insert(img)
	local scale = rDraw.height / img.height 
	img.xScale,img.yScale = scale,scale
end 

function ViewRender:getPhantomImage()
	return display.newImage("images/phantom.png",0,0)
end 

local ModernViewRender = ViewRender:new()

function ModernViewRender:renderBackground(width,height,skyHeight)
	local background = display.newImage(self.m_group,"images/skybox.png",0,0)
	background.anchorX,background.anchorY = 0,0
	background.width,background.height = width,skyHeight
	background = display.newImage(self.m_group,"images/stone.png",0,skyHeight)
	background.anchorX,background.anchorY = 0,0
	background.width,background.height = width,height-skyHeight
end 

function ModernViewRender:getWallImage(type)
	if type == "f" then return display.newImage("images/stone.png",0,0) end
	return display.newImage("images/wall.png",0,0)
end 

function ModernViewRender:getPhantomImage()
	local img = display.newImage("images/ghost.png",0,0)
	img.alpha = 0.7 
	return img
end 

return ModernViewRender

