--- ************************************************************************************************************************************************************************
--- ************************************************************************************************************************************************************************
---
---				Name : 		tutorial.lua
---				Purpose :	On screen tutorial utility class
---				Created:	5th July 2014
---				Author:		Paul Robson (paul@robsons.org.uk)
---				License:	MIT
---
--- ************************************************************************************************************************************************************************
--- ************************************************************************************************************************************************************************

-- Standard OOP (with Constructor parameters added.)
_G.Base =  _G.Base or { new = function(s,...) local o = { } setmetatable(o,s) s.__index = s o:initialise(...) return o end, initialise = function() end }

local Executive = require("system.executive")

local TutorialItem = Executive:createClass()

function TutorialItem:constructor(info,eData)
	self.m_group = display.newGroup()
	local x,y = info.x / 100 * display.contentWidth, info.y / 100 * display.contentHeight
	for i = 1,#info.pointers/2 do 
		local x1,y1 = info.pointers[i*2-1]/100*display.contentWidth, info.pointers[i*2]/100*display.contentHeight
		local l = display.newLine(x,y,x1,y1)
		l.strokeWidth = math.max(1,display.contentWidth/100) 
		l:setStrokeColor(0,1,0)
		local c = display.newCircle(x1,y1,display.contentWidth/40)
		c.strokeWidth = 2 c:setFillColor(0,0,1)
		self.m_group:insert(l) 
		self.m_group:insert(c)
	end 
	local txt = display.newText({ parent = self.m_group, text = info.text,
								  x = x,y = y , width = display.contentWidth/3.3, height = 0,
								  font = system.nativeFont,fontSize = display.contentWidth/24,align = "center"})

	local bw,bh = txt.width * 1.1,txt.height * 1.1
	local box = display.newRoundedRect(self.m_group,x,y,bw,bh,bw / 10)
	txt:toFront() txt:setFillColor(1,1,0) box:setFillColor(1,0,0) box.strokeWidth = 2
	self.m_group.alpha = 0
	transition.to(self.m_group,{ time = 1000, alpha = 1.0})
	self:insert(self.m_group)
	-- TODO: Self destruct (with delay to fade out), message back.
	-- TODO: Add group listener, causes cancel message to be send
end 

function TutorialItem:destructor() 
	self.m_group:removeSelf()
end 

local TutorialManager = Base:new()

function TutorialManager:constructor(info,eData)
	self.m_tutorialList = info.tutorialList
	assert(self.m_tutorialList ~= nil,"Missing tutorial data")
	self.m_nextTutorial = 1
	self:createTutorial()
end 

function TutorialManager:destructor()
	self.m_tutorialList = nil 
	self.m_nextTutorial = nil
end 

function TutorialManager:createTutorial()
	if self.m_nextTutorial > #self.m_tutorialList then return end 
	local tutorialInfo = self.m_tutorialList[self.m_nextTutorial]
	self.m_nextTutorial = self.m_nextTutorial + 1
	TutorialItem:new(self:getExecutive(),
		{ x = tutorialInfo.x,y = tutorialInfo.y, text = tutorialInfo.text, pointers = tutorialInfo.pointers, target = self, showTime = 3000 })
end



return TutorialManager 
