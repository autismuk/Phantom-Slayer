--- ************************************************************************************************************************************************************************
--- ************************************************************************************************************************************************************************
---
---				Name : 		screens.lua
---				Purpose :	Title/End Game state code
---				Created:	5th July 2014
---				Author:		Paul Robson (paul@robsons.org.uk)
---				License:	MIT
---
--- ************************************************************************************************************************************************************************
--- ************************************************************************************************************************************************************************

local ExecutiveFactory = require("system.game")
local Executive = require("system.executive")
local SCO = require("utils.screen")
require("system.fontmanager")

--- ************************************************************************************************************************************************************************
--//																The Start Game Screen
--- ************************************************************************************************************************************************************************

local StartGameFactory = ExecutiveFactory:new()

function StartGameFactory:preOpen(info,eData)
	local ex = self:getExecutive()
	local txo = display.newBitmapText("PHANTOM SLAYER",0,0,"dub",64):setTintColor(1,1,0) txo.xScale = 0.7 txo.yScale = 1.3
	SCO.ScreenObject:new(ex,{ object = txo,rectangle = { 50,15 } })
	SCO.ScreenObject:new(ex,{ object = display.newBitmapText("WRITTEN BY PAUL ROBSON",0,0,"dub",32):setTintColor(0,1,1), rectangle = { 50,32 }})
	SCO.ScreenObject:new(ex,{ object = display.newBitmapText("BASED ON THE GAME BY KEN KALISH",0,0,"dub",24):setTintColor(0,1,1), rectangle = { 50,40 }})
	SCO.ScreenObject:new(ex,{ object = display.newBitmapText("SPEED",0,0,"dub",42), rectangle = { 25,54 }})
	SCO.ScreenObject:new(ex,{ object = display.newBitmapText("STYLE",0,0,"dub",42), rectangle = { 25,66 }})
	SCO.StateChangeObject:new(ex,{ object = "images/maze.png", rectangle = { 75,70,24,30 }}):makeClickable("play"):highlight()
	local e1 = { { "DOZY",10000 }, { "SLOW",6000 }, { "MEDIUM",4000 }, { "FAST",2000 } }
	local e2 = { { "MODERN", false }, { "RETRO", true }}
	SCO.ScreenObject:new(ex,{ object =  display.newBitmapText("",0,0,"dub",42):setTintColor(0,1,0),rectangle = { 75,54 }, data = e1 }):makeClickable("phantomSpeed",nil)
	SCO.ScreenObject:new(ex,{ object =  display.newBitmapText("",0,0,"dub",42):setTintColor(0,1,0),rectangle = { 75,66 }, data = e2 }):makeClickable("retro",nil)
	ex:addLibraryObject("utils.music",{ music = "music.mp3" })
end 

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

return { StartGameFactory = StartGameFactory, EndGameFactory = EndGameFactory }


