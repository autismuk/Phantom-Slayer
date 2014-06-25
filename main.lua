display.setStatusBar(display.HiddenStatusBar)

local ExecutiveFactory = require("system.game")
local Executive = require("system.executive")
local Maze = require("classes.maze")

local executive = Executive:new()

local MainGameFactory = ExecutiveFactory:new()

function MainGameFactory:preOpen(info)
	math.randomseed(42)
	local executive = self:getExecutive()
	executive:addLibraryObject("classes.maze"):name("maze")

	player = executive:addLibraryObject("classes.player", { maze = executive.e.maze })
	executive.e.maze:add(1,Maze.TELEPORT,player:getLocation(),5) 

	executive:addLibraryObject("classes.viewrender","ModernViewRender"):name("render3D")
	executive:addLibraryObject("classes.maprender"):name("render2D")

	fakePhantom = {}
	executive.e.maze:put(player.x,player.y-3,Maze.TELEPORT)
	fakePhantom[1] = { x = player.x,y = player.y - 2 }
	--fakePhantom[1] = { x = player.x,y = player.y - 1 }
	c = executive.e.render3D:render(executive.e.maze,player,fakePhantom,440,300)
	c.x,c.y = 20,10

	c1 = executive.e.render2D:render(executive.e.maze,player,fakePhantom,120,120)
	c1.x,c1.y = 320,15
	c1.alpha = 0.7
end

Game:addState("play",MainGameFactory:new(),{ endGame = { target = "play" }})
Game:start("play")
