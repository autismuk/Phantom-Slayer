display.setStatusBar(display.HiddenStatusBar)

require("strict")

local ExecutiveFactory = require("system.game")
local Executive = require("system.executive")

--- ************************************************************************************************************************************************************************
--- ************************************************************************************************************************************************************************

local ScreenObject = Executive:createClass()

function ScreenObject:constructor(info) 
	info.rectangle = info.rectangle or {}
	info.rectangle[1] = (info.rectangle[1] or 0) * display.contentWidth / 100
	info.rectangle[2] = (info.rectangle[2] or 0) * display.contentHeight / 100
	if info.rectangle[3] ~= nil then 
		info.rectangle[3] = (info.rectangle[3] or 100) * display.contentWidth / 100
		info.rectangle[4] = (info.rectangle[4] or 100) * display.contentHeight / 100
	end
	self.m_object = info.object
	if type(self.m_object) == "string" then 
			self.m_object = display.newImage(self.m_object,0,0) 
	end
	if self.m_object == nil then 
		self:createObject()
	end
	self.m_object.anchorX,self.m_object.anchorY = 0,0
	self.m_object.x,self.m_object.y = info.rectangle[1],info.rectangle[2]
	if info.rectangle[3] ~= nil then 
		self.m_object.width,self.m_object.height = info.rectangle[3],info.rectangle[4]
	end
	self:insert(self.m_object)
	if self.m_object.setAnchor ~= nil then self.m_object:setAnchor(0,0) end
	self.m_hasListener = false
	self.m_eventTarget = nil
end


function ScreenObject:destructor() 
	if self.m_hasListener then 
		self.m_object:removeEventListener("tap",self)
		self.m_hasListener = false 
	end 
	self.m_object:removeSelf()
	self.m_object = nil 
	self.m_eventTarget = nil
end 

function ScreenObject:makeClickable(tag,target)
	self.m_tag = tag or ""
	self.m_eventTarget = target or self 
	if not self.m_hasListener then 
		self.m_object:addEventListener("tap",self)
		self.m_hasListener = true
	end 
	return self
end 

function ScreenObject:tap(event)
	if self.m_eventTarget ~= nil then 
		self:sendMessage(self.m_eventTarget,{ name = "tap", tag = self.m_tag }) 
	end
end

function ScreenObject:createObject()
end 

--- ************************************************************************************************************************************************************************
--- ************************************************************************************************************************************************************************

local EndGameFactory = ExecutiveFactory:new()

function EndGameFactory:preOpen(info,eData)
	print(eData.score)
	local o = ScreenObject:new(self:getExecutive(),{ object =  "images/maze.png",rectangle = { 75,75,24,24 }} ):makeClickable("demo")
	print(o:isAlive())
end 

Game:addState("endgame",EndGameFactory:new(), { })

--- ************************************************************************************************************************************************************************
--- ************************************************************************************************************************************************************************

MainGameFactory = require("states.game")

math.randomseed(42)
Game:addLibraryObject("utils.audio", { sounds = { "pulse","shoot","teleport","die","deadphantom" }} )
Game:addState("play",MainGameFactory:new(),{ gameover = { target = "endgame" }})
Game:start("play",{ score = 999 }) --, { retro = false, phantomCount = 14, phantomSpeed = 3000, phantomHits = 3, fireTime = 2000 })

--[[

	Clickable Screen Object
	Auto Screen Object
	Arrow information helper.
	Clickable actives

	Phantom 
	  		- can actually run through phantoms .... (might actually allow this)

"they would be extremely sticky to get free form speedily
--]]
