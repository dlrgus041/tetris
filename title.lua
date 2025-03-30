
local composer = require( "composer" )

local scene = composer.newScene()

-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------

local WIDTH = display.contentWidth
local HEIGHT = display.contentHeight

local mainGroup
local configGroup

local singlePlayButton
local localPVPButton
local localCoopButton

local function singlePlay(event)
	if (event.isPrimaryButtonDown) then composer.gotoScene("single") end
end

local function localPVP(event)
	if (event.isPrimaryButtonDown) then composer.gotoScene("pvp") end
end
--[[
local function localCoop(event)
	if (event.isPrimaryButtonDown) then composer.gotoScene("coop") end
end
]]--
-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------

-- create()
function scene:create( event )

	local sceneGroup = self.view
	-- Code here runs when the scene is first created but has not yet appeared on screen

	mainGroup = display.newGroup()
	sceneGroup:insert(mainGroup)

	local backgronud = display.newRect(mainGroup, WIDTH / 2, HEIGHT / 2, WIDTH, HEIGHT)
	backgronud:setFillColor(251 / 255, 206 / 255, 177 / 255, 0.8)

	singlePlayButton = display.newRoundedRect(mainGroup, WIDTH / 2, 5 * HEIGHT / 8, WIDTH / 3, HEIGHT / 10, 10)
	singlePlayButton:setFillColor(203 / 255, 125 / 255, 96 / 255, 0.8)

	localPVPButton = display.newRoundedRect(mainGroup, WIDTH / 2, 3 * HEIGHT / 4, WIDTH / 3, HEIGHT / 10, 10)
	localPVPButton:setFillColor(203 / 255, 125 / 255, 96 / 255, 0.8)

	localCoopButton = display.newRoundedRect(mainGroup, WIDTH / 2, 7 * HEIGHT / 8, WIDTH / 3, HEIGHT / 10, 10)
	localCoopButton:setFillColor(203 / 255, 125 / 255, 96 / 255, 0.8)

	local mainTitleString = display.newText({
		parent = mainGroup,
		text = "T E T R I S",
		x = WIDTH / 2,
		y = HEIGHT / 4,
		font = native.systemFont,
		fontSize = 100,
		align = "center"
	})
	mainTitleString:setFillColor(0, 0, 0)

	local singlePlayString = display.newText({
		parent = mainGroup,
		text = "Single Play",
		x = WIDTH / 2,
		y = 5 * HEIGHT / 8,
		font = native.systemFont,
		fontSize = 50,
		align = "center"
	})
	singlePlayString:setFillColor(0, 0, 0)

	local localPVPString = display.newText({
		parent = mainGroup,
		text = "Local PVP",
		x = WIDTH / 2,
		y = 3 * HEIGHT / 4,
		font = native.systemFont,
		fontSize = 50,
		align = "center"
	})
	localPVPString:setFillColor(0, 0, 0)

	local localCoopString = display.newText({
		parent = mainGroup,
		text = "Local Co-op",
		x = WIDTH / 2,
		y = 7 * HEIGHT / 8,
		font = native.systemFont,
		fontSize = 50,
		align = "center"
	})
	localCoopString:setFillColor(0, 0, 0)

	singlePlayButton:addEventListener("mouse", singlePlay)
	localPVPButton:addEventListener("mouse", localPVP)
--	localCoopButton:addEventListener("mouse", localCoop)
end


-- show()
function scene:show( event )

	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		-- Code here runs when the scene is still off screen (but is about to come on screen)

	elseif ( phase == "did" ) then
		-- Code here runs when the scene is entirely on screen

	end
end


-- hide()
function scene:hide( event )

	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		-- Code here runs when the scene is on screen (but is about to go off screen)

	elseif ( phase == "did" ) then
		-- Code here runs immediately after the scene goes entirely off screen

		composer.removeScene("title")
	end
end


-- destroy()
function scene:destroy( event )

	local sceneGroup = self.view
	-- Code here runs prior to the removal of scene's view

end


-- -----------------------------------------------------------------------------------
-- Scene event function listeners
-- -----------------------------------------------------------------------------------
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )
-- -----------------------------------------------------------------------------------

return scene
