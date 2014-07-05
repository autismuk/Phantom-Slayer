--- ************************************************************************************************************************************************************************
--- ************************************************************************************************************************************************************************
---
---				Name : 		main.lua
---				Purpose :	Phantom Slayer main program
---				Created:	5th July 2014
---				Author:		Paul Robson (paul@robsons.org.uk)
---				License:	MIT
---
--- ************************************************************************************************************************************************************************
--- ************************************************************************************************************************************************************************

display.setStatusBar(display.HiddenStatusBar)
require("strict")
local ExecutiveFactory = require("system.game")
local Executive = require("system.executive")

--- ************************************************************************************************************************************************************************
--																				Main program
--- ************************************************************************************************************************************************************************

MainGameFactory = require("states.game") 														-- The main game Factory
Titles = require("states.screens") 																-- Title and End game screens

Game:addLibraryObject("utils.audio", 															-- Preload Sounds
							{ sounds = { "pulse","shoot","teleport","die","deadphantom","click" }} )

Game:addState("start",Titles.StartGameFactory:new(), { play =  { target = "play"}}) 			-- start state
Game:addState("play",MainGameFactory:new(),{ gameover = { target = "endgame" }}) 				-- play state
Game:addState("endgame",Titles.EndGameFactory:new(), { restart = { target = "start"} }) 		-- endgame state

Game:start("play")  																			-- and run.

--[[

	Bugs:
		It is possible to run through phantoms (may keep this)

	Todo:
		Some way of highlighting clickables ??
		Arrow information helper.

	"they would be extremely sticky to get free form speedily

--]]
