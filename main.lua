display.setStatusBar(display.HiddenStatusBar)
Maze = require("classes.maze")
MapRender = require("classes.maprender")
ViewRender = require("classes.viewrender")
Player = require("classes.player")

math.randomseed(42)
m = Maze:new(20,20)
p = Player:new(m)
m:add(1,Maze.TELEPORT,p:getLocation(),5) 

m:put(p.x,p.y-3,Maze.TELEPORT)
--p.dx = 1 p.dy = 0 

mr = MapRender:new()
vw = ViewRender:new()
--m:print()
--print(m:getFillRatio())

fakePhantom = {}
fakePhantom[1] = { x = p.x,y = p.y - 2 }
c = vw:render(m,p,fakePhantom,480,320)
c.x,c.y = 0,0

c1 = mr:render(m,p,fakePhantom,100,100)
c1.x,c1.y = 365,15

