-----------------------------------------------------------------------------------------
--
-- main.lua
--
-----------------------------------------------------------------------------------------

local composer = require("composer")

display.setStatusBar(display.HiddenStatusBar)

math.random(os.time())

audio.reserveChannels(1)
audio.setVolume(0.5, {channel = 1})

composer.gotoScene("game")