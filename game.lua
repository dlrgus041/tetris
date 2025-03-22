
local composer = require( "composer" )

local scene = composer.newScene()

-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------

local backGroup
local mainGroup
local uiGroup

local background

local scoreVarText
local levelVarText
local remainVarText

local pauseBackgrond
local pauseImg
local pauseAt

local isGameOver = false
local gmeoverAlert

local board = {[-1] = {8, 8, 8, 8, 8, 8, 8, 8, 8, 8}, [0] = {8, 8, 8, 8, 8, 8, 8, 8, 8, 8}}
local isFull = {}

local color =
{
	{0, 1, 1},
	{1, 1, 0},
	{1, 0, 1},
	{0, 0, 1},
	{1, 0.5, 0},
	{0, 1, 0},
	{1, 0, 0},
	{1, 1, 1},
}

local pieces =
{
	{ -1, 0, 0,0 , 1,0, 2,0 }, -- I
	{ -1,-1, -1,0, 0,-1, 0,0 }, -- O
	{ -1,0, 0,0, 0,-1, 1,0 }, -- T
	{ -1,-1, -1,0, 0,0, 1,0 }, -- J
	{ -1,0, 0,0, 1,0, 1,-1 }, -- L
	{ -1,0, 0,0, 0,-1, 1,-1 }, -- S
	{ -1,-1, 0,0, 0,-1, 1,0 }, -- Z
	{ 0,0, 0,0, 0,0, 0,0 }, -- dummy
}

local pos = {x = 0, y = 20}
local piece = { 0,0, 0,0, 0,0, 0,0 }

local box = {}
local bag = {}

local gameBoardGroup
local nextPieceGroup
local storedPieceGroup

local nextPieceArea
local storedPieceArea

local nowPieceId = 8
local nextPieceId = 8
local storedPieceId = 1

local changePiece = false
local limit = 30
local remain = 1
local maxLine = 10
local line = 0
local level = 1
local score = 0

local function scanBoard()
	local isGameOver = true
	for col = 1, 20 do
		isFull[col] = true
		for row = 1, 10 do
			if (board[col][row] == 8) then
				isFull[col] = false
				break
			end
		end
		if (isFull[col] == true) then
			score = score + 1
			scoreVarText.text = score
			line = line + 1
			remainVarText.text = maxLine - line
		elseif (isGameOver == true) then isGameOver = false end
	end
	return isGameOver
end

local function rearrangeBoard()
	for bottom = 20, 1, -1 do
		if (isFull[bottom] == true) then
			local target = bottom - 1
			while (target > 0 and isFull[target] == true) do target = target - 1 end
			if (target > 0) then
				board[bottom] = board[target]
				isFull[bottom] = false
				board[target] = {8, 8, 8, 8, 8, 8, 8, 8, 8, 8}
				isFull[target] = true
			end
		end
	end
end

local function paintBlocks()
	for col = 1, 20 do
		for row = 1, 10 do
			local rgb = color[board[col][row]]
			gameBoardGroup[col][row]:setFillColor(rgb[1], rgb[2], rgb[3])
		end
	end
end

local function paintNextPiece(clear)
	local rgb = color[clear == true and 8 or nextPieceId]
	for i = 1, 4 do
		nextPieceGroup[3 + pieces[nextPieceId][2 * i]][3 + pieces[nextPieceId][2 * i - 1]]:setFillColor(rgb[1], rgb[2], rgb[3])
	end
end

local function paintStoredPiece(clear)
	local rgb = color[clear == true and 8 or storedPieceId]
	for i = 1, 4 do
		storedPieceGroup[3 + pieces[storedPieceId][2 * i]][3 + pieces[storedPieceId][2 * i - 1]]:setFillColor(rgb[1], rgb[2], rgb[3])
	end
end

local function getRandomPiece()
	paintNextPiece(true)
	if (#bag == 0) then
		for i = 1, 7 do
			bag[i] = i
			box[i] = math.random(49)
		end
		table.sort(bag, function(a, b) return box[a] > box[b] end)
	end
	nowPieceId = nextPieceId
	nextPieceId = table.remove(bag)
	paintNextPiece(false)
end

local function setPiece(n)
	for i = 1, 4 do
		board[pos.y + piece[2 * i]][pos.x + piece[2 * i - 1]] = n
	end
end

local function isPossible(dx, dy)
	for i = 1, 4 do
		local x0 = pos.x + dx + piece[2 * i - 1]
		local y0 = pos.y + dy + piece[2 * i]
		if (y0 > 20 or x0 < 1 or x0 > 10 or board[y0][x0] < 8) then return false end
	end
	return true
end

local function onKeyEvent(event)
	if (event.phase == "down") then
		setPiece(8)
		if (event.keyName == "escape") then
			if (isGameOver == false) then
				if (remain > 0) then
					pauseAt, remain = remain, -1
					pauseBackgrond.isVisible = true
					pauseImg.isVisible = true
				else
					pauseImg.isVisible = false
					pauseBackgrond.isVisible = false
					remain = pauseAt
				end
			end
		elseif (event.keyName == "leftShift" or event.keyName == "c") then
			if (changePiece == false) then
				paintStoredPiece(true)
				nowPieceId, storedPieceId = storedPieceId, nowPieceId
				pos.x, pos.y = 5, 0
				changePiece = true
				for i = 1, 8 do piece[i] = pieces[nowPieceId][i] end
				paintStoredPiece(false)
			end
		elseif (event.keyName == "space") then
			local bottom = 0
			while (isPossible(0, bottom + 1) == true) do bottom = bottom + 1 end
			pos.y = pos.y + bottom
		elseif (event.keyName == "up" or event.keyName == "x" or event.keyName == "numPad8") then
			local left, right = 0, 0
			for i = 1, 4 do
				piece[2 * i - 1], piece[2 * i] = -piece[2 * i], piece[2 * i - 1]
				left = math.min(left, piece[2 * i - 1])
				right = math.max(right, piece[2 * i - 1])
			end
			if (pos.x + left < 1) then
				pos.x = pos.x - left
			elseif (pos.x + right > 10) then
				pos.x = pos.x - right
			end
		elseif (event.keyName == "leftCtrl" or event.keyName == "z") then
			local left, right = 0, 0
			for i = 1, 4 do
				piece[2 * i - 1], piece[2 * i] = piece[2 * i], -piece[2 * i - 1]
				left = math.min(left, piece[2 * i - 1])
				right = math.max(right, piece[2 * i - 1])
			end
			if (pos.x + left < 1) then
				pos.x = pos.x - left
			elseif (pos.x + right > 10) then
				pos.x = pos.x - right
			end
		elseif (event.keyName == "down" or event.keyName == "numPad5") then
			if (isPossible(0, 1) == true) then pos.y = pos.y + 1 end
		elseif (event.keyName == "left" or event.keyName == "numPad4") then
			if (isPossible(-1, 0) == true) then pos.x = pos.x - 1 end
		elseif (event.keyName == "right" or event.keyName == "numPad6") then
			if (isPossible(1, 0) == true) then pos.x = pos.x + 1 end
		end
		setPiece(nowPieceId)
		paintBlocks()
	end
end

local function onFrameEvent()

	remain = remain - 1

	if (remain == 0) then
		setPiece(8)
		if (isPossible(0, 1) == false) then
			setPiece(nowPieceId)
			changePiece = false
			if (scanBoard() == false) then
				rearrangeBoard()
				getRandomPiece()
				for i = 1, 8 do piece[i] = pieces[nowPieceId][i] end
				pos.x, pos.y = 5, 0
			else
				-- show 'game_over' alert
			end
		else
			pos.y = pos.y + 1
		end

		if (line >= maxLine) then
			line = line - maxLine
			maxLine = maxLine + 5
			remainVarText.text = maxLine - line

			level = level + 1
			levelVarText.text = level

			limit = limit - 2
		end

		setPiece(nowPieceId)
		paintBlocks()
		remain = limit
	end
end

-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------

-- create()
function scene:create( event )

	local sceneGroup = self.view
	-- Code here runs when the scene is first created but has not yet appeared on screen

	backGroup = display.newGroup()
	sceneGroup:insert(backGroup)

	background = display.newRect(backGroup, display.contentCenterX, display.contentCenterY, display.contentWidth, display.contentHeight)
	background:setFillColor(251 / 255, 206 / 255, 177 / 255, 0.8)

	mainGroup = display.newGroup()
	sceneGroup:insert(mainGroup)

	local x1 = display.contentWidth / 4 - display.contentHeight / 8
	local x2 = 3 * display.contentWidth / 4 + display.contentHeight / 8
	local half = display.contentHeight / 40

	local scoreBoardArea = display.newRoundedRect(mainGroup, x1, display.contentHeight / 2, 20 * half, 20 * half, 12)
	scoreBoardArea:setFillColor(251 / 255, 206 / 255, 177 / 255, 0.8)
	scoreBoardArea:setStrokeColor(1, 1, 1)
	scoreBoardArea.strokeWidth = half / 2

	scoreArea = display.newRoundedRect(mainGroup, x1 - 6 * half, display.contentHeight / 2 - 5 * half, 7 * half, 3 * half, 2)
	scoreArea:setFillColor(203 / 255, 125 / 255, 96 / 255, 0.8)

	scoreVarArea = display.newRoundedRect(mainGroup, x1 + 4 * half, display.contentHeight / 2 - 5 * half, 10 * half, 3 * half, 2)
	scoreVarArea:setFillColor(203 / 255, 125 / 255, 96 / 255, 0.8)

	levelArea = display.newRoundedRect(mainGroup, x1 - 6 * half, display.contentHeight / 2, 7 * half, 3 * half, 2)
	levelArea:setFillColor(203 / 255, 125 / 255, 96 / 255, 0.8)

	levelVarArea = display.newRoundedRect(mainGroup, x1 + 4 * half, display.contentHeight / 2, 10 * half, 3 * half, 2)
	levelVarArea:setFillColor(203 / 255, 125 / 255, 96 / 255, 0.8)

	remainArea = display.newRoundedRect(mainGroup, x1 - 6 * half, display.contentHeight / 2 + 5 * half, 7 * half, 3 * half, 2)
	remainArea:setFillColor(203 / 255, 125 / 255, 96 / 255, 0.8)

	remainVarArea = display.newRoundedRect(mainGroup, x1 + 4 * half, display.contentHeight / 2 + 5 * half, 10 * half, 3 * half, 2)
	remainVarArea:setFillColor(203 / 255, 125 / 255, 96 / 255, 0.8)

	nextPieceArea = display.newRoundedRect(mainGroup, x2, display.contentHeight / 4, 12 * half, 12 * half, 12)
	nextPieceArea:setFillColor(1, 1, 1)

	storedPieceArea = display.newRoundedRect(mainGroup, x2, 3 * display.contentHeight / 4, 12 * half, 12 * half, 12)
	storedPieceArea:setFillColor(1, 1, 1)

	gameBoardGroup = display.newGroup()
	mainGroup:insert(gameBoardGroup)
	
	local start = display.contentWidth / 2 - display.contentHeight / 4

	for col = 1, 20 do
		local line = display.newGroup()
		local arr = {}
		for row = 1, 10 do
			local grid = display.newRect(line, start + (2 * row - 1) * half, (2 * col - 1) * half, 2 * half, 2 * half)
			grid:setStrokeColor(0.5, 0.5, 0.5, 0.8)
			grid.strokeWidth = half / 30
			arr[row] = 8
		end
		gameBoardGroup:insert(line)
		board[col] = arr
		isFull[col] = false
	end

	nextPieceGroup = display.newGroup()
	mainGroup:insert(nextPieceGroup)

	for col = 1, 5 do
		local line = display.newGroup()
		for row = 1, 5 do
			local grid = display.newRect(line, x2 - 5 * half + (2 * row - 1) * half, display.contentHeight / 4 - 5 * half + (2 * col - 1) * half, 2 * half, 2 * half)
			grid:setStrokeColor(0.5, 0.5, 0.5, 0.8)
			grid.strokeWidth = half / 30
		end
		nextPieceGroup:insert(line)
	end

	storedPieceGroup = display.newGroup()
	mainGroup:insert(storedPieceGroup)

	for col = 1, 5 do
		local line = display.newGroup()
		for row = 1, 5 do
			local grid = display.newRect(line, x2 - 5 * half + (2 * row - 1) * half, 3 * display.contentHeight / 4 - 5 * half + (2 * col - 1) * half, 2 * half, 2 * half)
			grid:setStrokeColor(0.5, 0.5, 0.5, 0.8)
			grid.strokeWidth = half / 30
		end
		storedPieceGroup:insert(line)
	end

	uiGroup = display.newGroup()
	sceneGroup:insert(uiGroup)

	local scoreText = display.newText({
		parent = uiGroup,
		text = "LINES",
		x = x1 - 6 * half,
		y = display.contentHeight / 2 - 5 * half,
		font = native.systemFont,
		fontSize = 30,
		align = "center"
	})
	scoreText:setFillColor(0, 0, 0)

	scoreVarText = display.newText({
		parent = uiGroup,
		text = "0",
		x = x1 + 4 * half,
		y = display.contentHeight / 2 - 5 * half,
		font = native.systemFont,
		fontSize = 30,
		align = "right",
		width = 9 * half
	})
	scoreVarText:setFillColor(0, 0, 0)

	local levelText = display.newText({
		parent = uiGroup,
		text = "LEVEL",
		x = x1 - 6 * half,
		y = display.contentHeight / 2,
		font = native.systemFont,
		fontSize = 30,
		align = "center"
	})
	levelText:setFillColor(0, 0, 0)

	levelVarText = display.newText({
		parent = uiGroup,
		text = "1",
		x = x1 + 4 * half,
		y = display.contentHeight / 2,
		font = native.systemFont,
		fontSize = 30,
		align = "right",
		width = 9 * half
	})
	levelVarText:setFillColor(0, 0, 0)

	local remainText = display.newText({
		parent = uiGroup,
		text = "REMAIN",
		x = x1 - 6 * half,
		y = display.contentHeight / 2 + 5 * half,
		font = native.systemFont,
		fontSize = 30,
		align = "center"
	})
	remainText:setFillColor(0, 0, 0)

	remainVarText = display.newText({
		parent = uiGroup,
		text = "10",
		x = x1 + 4 * half,
		y = display.contentHeight / 2 + 5 * half,
		font = native.systemFont,
		fontSize = 30,
		align = "right",
		width = 9 * half
	})
	remainVarText:setFillColor(0, 0, 0)

	local nextPieceText = display.newText({
		parent = uiGroup,
		text = "NEXT",
		x = x2,
		y = display.contentHeight / 4 - 8 * half,
		font = native.systemFont,
		fontSize = 50,
		align = "center"
	})
	nextPieceText:setFillColor(0, 0, 0)

	local storedPieceText = display.newText({
		parent = uiGroup,
		text = "STORAGE",
		x = x2,
		y = 3 * display.contentHeight / 4 - 8 * half,
		font = native.systemFont,
		fontSize = 50,
		align = "center"
	})
	storedPieceText:setFillColor(0, 0, 0)

	pauseBackgrond = display.newRect(uiGroup, display.contentCenterX, display.contentCenterY, display.contentWidth, display.contentHeight)
	pauseBackgrond:setFillColor(1, 1, 1, 0.4)
	pauseBackgrond.isVisible = false

	pauseImg = display.newImageRect(uiGroup, "pause.png", display.contentHeight / 2, display.contentHeight / 2)
	pauseImg.x = display.contentCenterX
	pauseImg.y = display.contentCenterY
	pauseImg.alpha = 0.8
	pauseImg.isVisible = false

	getRandomPiece()
	paintStoredPiece(false)
end


-- show()
function scene:show( event )

	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		-- Code here runs when the scene is still off screen (but is about to come on screen)

	elseif ( phase == "did" ) then
		-- Code here runs when the scene is entirely on screen

		Runtime:addEventListener("key", onKeyEvent)
		Runtime:addEventListener("enterFrame", onFrameEvent)
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
