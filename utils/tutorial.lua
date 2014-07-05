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

--- ************************************************************************************************************************************************************************
--//	This class is used by the manager, it is a single instance of a prompt
--- ************************************************************************************************************************************************************************

local TutorialItem = Executive:createClass()

--//	Build it - info contains the position x,y as a %, the text, and an array of point pairs as percents.

function TutorialItem:constructor(info,eData)
	self.m_group = display.newGroup()
	local x,y = info.x / 100 * display.contentWidth, info.y / 100 * display.contentHeight 		-- Convert positions to screen coordinates
	for i = 1,#info.pointers/2 do  																-- work through all the point pairs.
		local x1 = info.pointers[i*2-1]/100*display.contentWidth 								-- calculate final position e.g. where the circle is
		local y1 = info.pointers[i*2]/100*display.contentHeight
		local l = display.newLine(x,y,x1,y1) 													-- line from message to circle
		l.strokeWidth = math.max(1,display.contentWidth/100) 
		l:setStrokeColor(0,1,0)
		local c = display.newCircle(x1,y1,display.contentWidth/40) 								-- circle on the end
		c.strokeWidth = 2 c:setFillColor(0,0,1) 												
		self.m_group:insert(l)  																--put in the group
		self.m_group:insert(c)
	end 

	local txt = display.newText({ parent = self.m_group, text = info.text, 						-- create text box
								  x = x,y = y , width = display.contentWidth/3.3, height = 0,
								  font = system.nativeFont,fontSize = display.contentWidth/24,align = "center"})

	local bw,bh = txt.width * 1.1,txt.height * 1.1 												-- size of bounding box
	local box = display.newRoundedRect(self.m_group,x,y,bw,bh,bw / 10) 							-- create bounding box
	txt:toFront() txt:setFillColor(1,1,0) box:setFillColor(1,0,0) box.strokeWidth = 2 			-- set up, bring text to front
	self.m_group.alpha = 0 																		-- fade it in
	transition.to(self.m_group,{ time = 1000, alpha = 1.0})
	self:insert(self.m_group) 																	-- put in executive display group.
	self:addSingleTimer((info.showTime or 3000)+ 1000) 											-- fire timer allowing for fade in.
	self.m_target = info.target  																-- remember who to tell when done.
	self.m_group:addEventListener("tap",self) 													-- listen for taps to cancel instructions.
end 

--//	Called on timer 

function TutorialItem:onTimer(tag,timerID) 
	transition.to(self.m_group,{ time = 1000, alpha = 0.0 }) 									-- hide it again
	timer.performWithDelay(1000, function(e)  													-- after hidden
		self:sendMessage(self.m_target, { name = "done" }) 										-- tell caller it is complete
		self:delete() 																			-- and kill it.
	end)
end 

--//	Handle taps

function TutorialItem:tap(e)
	self:sendMessage(self.m_target, { name = "cancel" }) 										-- tell caller we are cancelling
	self:delete() 																				-- get rid of it.
end 

--//	Clear up

function TutorialItem:destructor() 
	self.m_group:removeEventListener("tap",self) 												-- remove event listener
	self.m_group:removeSelf() 																	-- remove objects
	self.m_group = nil self.m_target = nil 														-- null references
end 

--- ************************************************************************************************************************************************************************
--//					This class manages an array of tutorial items. This uses a static member so it only happens once, when you start it up. 
--- ************************************************************************************************************************************************************************

local TutorialManager = Base:new()

--//	Create - passed the tutorial list in the info structure

function TutorialManager:constructor(info,eData)
	self.m_tutorialList = info.tutorialList 													-- remember the tutorial list
	assert(self.m_tutorialList ~= nil,"Missing tutorial data") 									-- check its there
	self.m_nextTutorial = 1 																	-- start with #1
	if TutorialManager.hasUsed then self.m_nextTutorial = #self.m_tutorialList+1 end 			-- if already fired, then exit immediately by pointing past last one.
	TutorialManager.hasUsed = true 																-- set the fired flag so it can't be run again.
	self:createTutorial() 																		-- create it
end 

--//	Tidy up

function TutorialManager:destructor()
	self.m_tutorialList = nil 
	self.m_nextTutorial = nil
end 

--// 	Create a new tutorial item - e.g. a text box with optional multiple lines to screen objects.

function TutorialManager:createTutorial()
	if self.m_nextTutorial > #self.m_tutorialList then 											-- reached the end of the list
		self:delete() 																			-- destroy this object and return.
		return 
	end 
	local tutorialInfo = self.m_tutorialList[self.m_nextTutorial] 								-- get next
	self.m_nextTutorial = self.m_nextTutorial + 1 												-- bump index
	TutorialItem:new(self:getExecutive(), 														-- create a new tutorial item
		{ x = tutorialInfo.x,y = tutorialInfo.y, text = tutorialInfo.text, pointers = tutorialInfo.pointers, target = self, showTime = 3000 })
end

--//	Handle messages

function TutorialManager:onMessage(sender,message)
	if message.name == "cancel" then self.m_nextTutorial = #self.m_tutorialList+1 end 			-- if cancel, move past last message ending automatically
	self:createTutorial() 																		-- do next tutorial.
end 

return TutorialManager 
