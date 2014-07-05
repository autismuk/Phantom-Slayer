
--- ************************************************************************************************************************************************************************
---
---				Name : 		music.lua
---				Purpose :	Simple Background Music Class
---				Created:	5 July 2014
---				Author:		Paul Robson (paul@robsons.org.uk)
---				License:	MIT
---
--- ************************************************************************************************************************************************************************

-- Standard OOP (with Constructor parameters added.)
_G.Base =  _G.Base or { new = function(s,...) local o = { } setmetatable(o,s) s.__index = s o:initialise(...) return o end, initialise = function() end }


--- ************************************************************************************************************************************************************************
--//													Class which plays background music until destroyed
--- ************************************************************************************************************************************************************************

local BackgroundMusicPlayer = Base:new()

--//	Constructor. info contains a music entry (defaults to music.mp3) which is in the audio directory, a fadeIn time (defaults to 2s) and 
--//	a fadeOut time (defaults to fadeIn time)

function BackgroundMusicPlayer:constructor(info)
	self.m_stream = audio.loadStream("audio/"..(info.music or "music.mp3"))						-- get stream file name
	local fadeIn = info.fadeIn or 2000 															-- fade in time
	self.m_fadeOutTime = info.fadeOut or fadeIn 												-- fade out time
	if self.m_stream ~= nil then 																-- stream if loaded okay.
		self.m_channel = audio.play(self.m_stream, { loops = -1, fadein = fadeIn }) 			-- remember channel
	end
end 

--//	Destructor
function BackgroundMusicPlayer:destructor()
	if self.m_stream ~= nil then 																-- if stream present
		audio.fadeOut({ time = self.m_fadeOutTime })											-- fade it out
		timer.performWithDelay(self.m_fadeOutTime,function(e) 									-- after the same time period
			audio.dispose(self.m_stream) 														-- clear the stream
			self.m_stream = nil 																-- lose the reference
			audio.setVolume(1,{ channel = self.m_channel })  									-- reset the volume - needed to unpick fadeOut()
		end)
	end
end

return BackgroundMusicPlayer
