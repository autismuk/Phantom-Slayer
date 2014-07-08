--- ************************************************************************************************************************************************************************
---
---				Name : 		audio.lua
---				Purpose :	Simple Audio Cache Class
---				Created:	29 June 2014
---				Author:		Paul Robson (paul@robsons.org.uk)
---				License:	MIT
---
--- ************************************************************************************************************************************************************************


-- Standard OOP (with Constructor parameters added.)
_G.Base =  _G.Base or { new = function(s,...) local o = { } setmetatable(o,s) s.__index = s o:initialise(...) return o end, initialise = function() end }

--- ************************************************************************************************************************************************************************
--//																				Audio Cache
--- ************************************************************************************************************************************************************************

local AudioCache = Base:new()

--//	Constructor - info.sounds is a list of samples, default is mp3.
--//	@info 	[table]		Constructor parameters

function AudioCache:constructor(info)
	self:name("audio") 																			-- access this via e.audio
	self.m_soundCache = {} 																		-- cached audio
	for _,name in ipairs(info.sounds) do  														-- work through list of audio filenames
		local fName = self:getFileName(name)													-- get full file name
		local stub = fName:match("%/(.*)%."):lower() 											-- get the 'stub', the name without the extension as l/c 
		self.m_soundCache[stub] = audio.loadSound(fName) 										-- load and store in cache.
	end
end 

--//	Play a sound effect from the cache.
--//	@name 	[string]			stub name, case insensitive
--//	@options [table] 			options for play, see audio.play() documents

function AudioCache:play(name,options)
	name = name:lower() 																		-- case irrelevant
	assert(self.m_soundCache[name] ~= nil,"Unknown sound "..name) 								-- check sound actually exists
	audio.play(self.m_soundCache[name],options) 												-- play it 
end 

--//	Given a stub file, get the full file name
--//	@name 	[string]		short file name
--//	@return [string]		reference to file, in audio subdirectory.

function AudioCache:getFileName(name)
	if name:find("%.") == nil then name = name .. ".mp3" end  									-- no extension, default to .mp3
	return "audio/"..name 																		-- actual name of file in audio subdirectory.
end 

--//	Check if sound present.
--//	@name 	[string]		short name of sound
--//	@return [boolean]		true if present.

function AudioCache:isSoundPresent(name)
	return (self.m_soundCache[name:lower()] ~= nil)
end 

--//	Destructor

function AudioCache:destructor()
	for _,ref in pairs(self.m_soundCache) do audio.dispose(ref) end 							-- clear out the cache.
	self.m_soundCache = nil 																	-- nil so references lost.
end 

return AudioCache
