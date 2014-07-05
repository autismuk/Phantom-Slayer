--- ************************************************************************************************************************************************************************
--- ************************************************************************************************************************************************************************
---
---				Name : 		screen.lua
---				Purpose :	Screen Display Objects - information screens etc.
---				Created:	2nd July 2014
---				Author:		Paul Robson (paul@robsons.org.uk)
---				License:	MIT
---
--- ************************************************************************************************************************************************************************
--- ************************************************************************************************************************************************************************

local Executive = require("system.executive")

--- ************************************************************************************************************************************************************************
--//	Represents a screen object, with a position, size, possible data, listener, and also handles choices changing on click.
--- ************************************************************************************************************************************************************************

local ScreenObject = Executive:createClass()

--//	Constructor. info can contain a rectangle { x,y,w,h } where all values are % of width, height, an object, which is the display 
--// 	object, and selector data, an array of 2 element arrays of displayed text and returned values.
--//	@info 	[table]		Constructor data

function ScreenObject:constructor(info) 
	info.rectangle = info.rectangle or {}  														-- Drawing rectangle
	info.rectangle[1] = (info.rectangle[1] or 0) * display.contentWidth / 100 					-- Scale position to display
	info.rectangle[2] = (info.rectangle[2] or 0) * display.contentHeight / 100
	if info.rectangle[3] ~= nil then  															-- if width/height provided
		info.rectangle[3] = (info.rectangle[3] or 100) * display.contentWidth / 100 			-- scale that
		info.rectangle[4] = (info.rectangle[4] or 100) * display.contentHeight / 100
	end
	self.m_object = info.object 																-- provided object
	if type(self.m_object) == "string" then  													-- could be the name of an image
			self.m_object = display.newImage(self.m_object,0,0) 
	end
	if self.m_object == nil then  																-- or may need creating
		self:createObject(info)
	end
	self.m_object.x = info.rectangle[1]
	self.m_object.y = info.rectangle[2]
	if info.rectangle[3] ~= nil then 															-- if width provided, set that.
		self.m_object.width,self.m_object.height = info.rectangle[3],info.rectangle[4]
		self.m_object.x = info.rectangle[1] + info.rectangle[3]/2 								-- reposition so middle of object on coordinates
		self.m_object.y = info.rectangle[2] + info.rectangle[4]/2
	end
	self.m_object.anchorX,self.m_object.anchorY = 0.5,0.5 										-- fix anchor
	self:insert(self.m_object) 																	-- insert into the executive group
	if self.m_object.setAnchor ~= nil then 														-- fix for font manager
		self.m_object:setAnchor(0.5,0.5)
		self.m_object:moveTo(self.m_object.x,self.m_object.y)
	end 
	self.m_hasListener = false 																	-- no listener
	self.m_eventTarget = nil 																	-- no target
	self.m_selectorData = info.data 															-- selector data if provided
end

--//	Tidy up.

function ScreenObject:destructor() 
	if self.m_hasListener then  																-- if it has a listener
		self.m_object:removeEventListener("tap",self) 											-- remove the listener
		self.m_hasListener = false  															-- clear marker
	end 
	self.m_object:removeSelf() 																	-- remove display object
	self.m_object = nil 																		-- and clear up
	self.m_eventTarget = nil
	self.m_index = nil
	self.m_selectorData = nil
end 

--//	Make a screen object clickable. It can have a tag and target. If there is no target, it means it is a changing value option 
--//	and is dealt with appropriately, in this case the tag is the return values key, and if there is a target it simply sends 
--// 	a message with name = "tap", tag = [tag] to the object.
--//	@tag 	[string]		tag to identify clicked object / key
--//	@target [object]		object to send message to, if nil then it is a control value
--//	@return [object]		chaining

function ScreenObject:makeClickable(tag,target)
	self.m_tag = tag or "" 																		-- default no tag
	if not self.m_hasListener then  															-- add a listener if required.
		self.m_object:addEventListener("tap",self)
		self.m_hasListener = true  																-- mark as having one.
	end 
	if target == nil then 																		-- if target is nil then this is a click-change object.
		self.m_index = 1 																		-- reset the index
		self:updateDisplayObject(self.m_index,self.m_object) 									-- update the text.
		self:tag("+hasvalue")																	-- it now returns a value.
	end
	self.m_eventTarget = target 																-- set event target.
	return self 																				-- chainable
end 

--//	Update the display object to the given index. By default, this is textual, but it could change the image in a group
--//	or alternatively select one in an animation.
--//	@index 	[number]		index to select 
--//	@object [object] 		display object

function ScreenObject:updateDisplayObject(index,object)
	if object.setText ~= nil then  																-- use setText() if it has it
		self.m_object:setText(self:getDisplayValue(index))
	else  																						-- otherwise assign to text.
		self.m_object.text = self:getDisplayValue(index)
	end
end 

--//	Handle screen taps
--//	@event [event]			event 

function ScreenObject:tap(event)
	if Game.e.audio:isSoundPresent("click") then Game.e.audio:play("click") end 				-- click if there is a click sound.
	if self.m_eventTarget ~= nil then  															-- is there a target ?
		self:sendMessage(self.m_eventTarget,{ name = "tap", tag = self.m_tag }) 				-- if so, send it a message.
	else 
		self:click() 																			-- no target, it is clickable.
	end
	return true
end

--//	Handle a click - called when there is no target.

function ScreenObject:click() 
	self.m_index = self.m_index + 1  															-- bump index.
	if self.m_index > self:getValueCount() then self.m_index = 1 end  							-- wrap round.
	self:updateDisplayObject(self.m_index,self.m_object) 										-- update the option.
	transition.to(self.m_object,{ time = 200, xScale = 1.2,yScale = 1.2, 						-- make the option 'blip'
			onComplete = function() transition.to(self.m_object, { time = 200, xScale = 1, yScale = 1}) end })
end 

--//	Get the number of display values.
--//	@return 	[number]	number of values 

function ScreenObject:getValueCount() 
	return #self.m_selectorData 
end 

--//	Get the displayed value - what is shown on the screen
--//	@n 			[number]	relevant index
--//	@return 	[string]	displayed value

function ScreenObject:getDisplayValue(n) 
	return self.m_selectorData[n][1] 
end 

--//	Get the returned value - so for example the displayed value may be slow, medium, fast and the returned value may be 1,2,3
--//	@n 			[number]	relevant index
--//	@return 	[string]	value to put in table to pass on

function ScreenObject:getReturnValue(n) 
	return self.m_selectorData[n][2] 
end 

--//	Get the key the returned value is stored under - normally the tag used with makeClickable()
--//	@return 	[string] 	string to store returned value in.

function ScreenObject:getInfoKey() 
	return self.m_tag 
end 

--- ************************************************************************************************************************************************************************
--//	An object with the functionality of a screen object, save that when clicked it switches to a new state, having collected all the values associated 
--//	on to the screen.
--- ************************************************************************************************************************************************************************

local StateChangeObject = Executive:createClass(ScreenObject)

--//	Constructor

function StateChangeObject:constructor(info)
	ScreenObject.constructor(self,info)
end 

--//	Make an object clickable, given the new state (stored in m_tag)
--//	@newState 	[string] 		name of new state
--//	@return 	[object]		self

function StateChangeObject:makeClickable(newState)
	ScreenObject.makeClickable(self,newState,self) 												-- override make clickable so message to self
	return self
end 

--//	Highlight object by making it pulse slightly
--//	@return 	[object]		self

function StateChangeObject:highlight()
	self:tag("+update")
	return self
end 

--//	Handle message - this receives the tap message after processing.
--//	@sender 	[object] 		where it comes from
--//	@message 	[object] 		the message.

function StateChangeObject:onMessage(sender,message)
	local info = {} 																			-- passed on values.
	local values = self:query("hasvalue") 														-- look for all objects with associated value.
	for _,ref in pairs(values.objects) do  														-- work through them
		local key = ref:getInfoKey() 															-- get the key, check if duplicated
		assert(values[key] == nil,"key "..key.." is duplicated") 								
		values[key] = ref:getReturnValue(ref.m_index) 											-- store it
		-- print(key,values[key])
	end 
	Game:event(self.m_tag,values)																-- switch state passing return value.
end 

--//	Make it pulse 

function StateChangeObject:onUpdate(deltaTime,deltaMillisecs,current)
	local time = math.floor(current/100) % 12 													-- position in cycle
	if time > 6 then time = 11-time end 														-- make loop up and down
	local scale = 0.95+time/40 																	-- work out scale 
	self.m_object.xScale,self.m_object.yScale = scale,scale 									-- scale object.
end 

return { ScreenObject = ScreenObject, StateChangeObject = StateChangeObject }

--[[
	local e1 = { { "LINE 1",111 }, { "LINE 2",222 }, { "LINE 3",3333} }
	local e2 = { { "YES", true}, { "NO", false }}
	SCO.ScreenObject:new(self:getExecutive(),{ object =  display.newBitmapText("",0,0,"dub",52),rectangle = { 50,25 }, data = e1 }):makeClickable("counter",nil)
	SCO.ScreenObject:new(self:getExecutive(),{ object =  display.newBitmapText("",0,0,"dub",52),rectangle = { 50,35 }, data = e2 } ):makeClickable("playnow",nil)
--]]