display.setStatusBar(display.HiddenStatusBar)

require("strict")

local ExecutiveFactory = require("system.game")
local Executive = require("system.executive")
local SCO = require("utils.screen")
require("system.fontmanager")

--- ************************************************************************************************************************************************************************
--//																The End Game Screen
--- ************************************************************************************************************************************************************************

local EndGameFactory = ExecutiveFactory:new()

function EndGameFactory:preOpen(info,eData)
	local txo = display.newBitmapText("GAME OVER",0,0,"dub",64):setTintColor(1,1,0)
	SCO.ScreenObject:new(self:getExecutive(),{ object = txo,rectangle = { 50,25 } })
	SCO.ScreenObject:new(self:getExecutive(),{ object = display.newBitmapText("SCORE "..eData.score,0,0,"dub",42),rectangle = { 50,50 }})
	SCO.StateChangeObject:new(self:getExecutive(), { object = "images/restart.png", rectangle = { 75,70,24,30 }}):makeClickable("restart"):highlight()
end 


--- ************************************************************************************************************************************************************************
--- ************************************************************************************************************************************************************************

MainGameFactory = require("states.game")

math.randomseed(42)
Game:addLibraryObject("utils.audio", { sounds = { "pulse","shoot","teleport","die","deadphantom" }} )
Game:addState("play",MainGameFactory:new(),{ gameover = { target = "endgame" }})
Game:addState("endgame",EndGameFactory:new(), { restart = { target = "play"} })

Game:start("endgame",{ score = 999 }) --, { retro = false, phantomCount = 14, phantomSpeed = 3000, phantomHits = 3, fireTime = 2000 })

--[[

	Transparent click on screen.
	Delayed transferrer.

	Arrow information helper.

	Phantom 
	  		- can actually run through phantoms .... (might actually allow this)

"they would be extremely sticky to get free form speedily
--]]
