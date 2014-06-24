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
c = vw:render(m,p,fakePhantom,440,300)
c.x,c.y = 20,10

c1 = mr:render(m,p,fakePhantom,120,120)
c1.x,c1.y = 320,15
c1.alpha = 0.7

