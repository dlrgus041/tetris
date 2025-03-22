
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
local pocket = {}

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
local maxScore = 10
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
		if (isGameOver == true and isFull[col] == false) then isGameOver = false end
	end
	return isGameOver
end

local function rearrangeBoard()
	for bottom = 20, 1, -1 do
		if (isFull[bottom] == true) then
			for target = bottom - 1, 1, -1 do
				if (isFull[target] == false) then
					board[bottom] = board[target]
					isFull[bottom] = false
					board[target] = {8, 8, 8, 8, 8, 8, 8, 8, 8, 8}
					isFull[target] = true
					score = score + 1
					break
				end
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
	if (#pocket == 0) then
		for i = 1, 7 do
			pocket[i] = i
			box[i] = math.random(49)
		end
		table.sort(pocket, function(a, b) return box[a] > box[b] end)
	end
	nowPieceId = nextPieceId
	nextPieceId = table.remove(pocket)
	paintNextPiece(false)
end

local function setPiece(n)
	for i = 1, 4 do
		board[pos.y + piece[2 * i]][pos.x + piece[2 * i - 1]] = n
	end
end

local function getMin()
	local ret = 0
	for i = 1, 4 do ret = math.min(ret, piece[2 * i - 1]) end
	return ret
end

local function getMax()
	local ret = 0
	for i = 1, 4 do ret = math.max(ret, piece[2 * i - 1]) end
	return ret
end

local function predictBottom(nowPieceId)
	local y0 = pos.y
	while (y0 <= 20) do
		local impossible = false
		y0 = y0 + 1
		for i = 1, 4 do
			local y = y0 + piece[2 * i]
			if (y > 20 or board[y][pos.x + piece[2 * i - 1]] < 8) then
				impossible = true
				break
			end
		end
		if (impossible == true) then break end
	end
	return y0 - 1
end

local function onKeyEvent(event)
	if (event.phase == "down") then
		setPiece(8)
		if (event.keyName == "escape") then
			if (isGameOver == false) then
				if (remain > 0) then
					pauseAt = remain
					remain = -1
					pauseBackgrond.isVisible = true
					pauseImg.isVisible = true
				else
					pauseImg.isVisible = false
					pauseBackgrond.isVisible = false
					remain = pauseAt
				end
			end
		elseif (event.keyName == "leftShift") then
			if (changePiece == false) then
				paintStoredPiece(true)
				nowPieceId, storedPieceId = storedPieceId, nowPieceId
				pos.x, pos.y = 5, 0
				changePiece = true
				for i = 1, 8 do piece[i] = pieces[nowPieceId][i] end
				paintStoredPiece(false)
			end
		elseif (event.keyName == "space") then
			pos.y = predictBottom(nowPieceId)
		elseif (event.keyName == "up") then
			if (pos.y < predictBottom(nowPieceId)) then
				for i = 1, 4 do piece[2 * i - 1], piece[2 * i] = -piece[2 * i], piece[2 * i - 1] end
			end
			local left, right = getMin(), getMax()
			if (pos.x + left < 1) then
				pos.x = pos.x - left
			elseif (pos.x + right > 10) then
				pos.x = pos.x - right
			end
		elseif (event.keyName == "down") then
			if (pos.y < predictBottom(nowPieceId)) then
				pos.y = pos.y + 1
			end
		elseif (event.keyName == "left") then
			if (pos.x + getMin() > 1) then
				pos.x = pos.x - 1
			end
		elseif (event.keyName == "right") then
			if (pos.x + getMax() < 10) then
				pos.x = pos.x + 1
			end
		end
		setPiece(nowPieceId)
		paintBlocks()
	end
end

local function onFrameEvent()

	remain = remain - 1

	if (remain == 0) then
		setPiece(8)
		if (pos.y == predictBottom(nowPieceId)) then
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

		if (score > maxScore) then
			score = score - maxScore
			maxScore = maxScore + 5
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

	local x0 = 3 * display.contentWidth / 4 + display.contentHeight / 8
	local half = display.contentHeight / 40

	nextPieceArea = display.newRoundedRect(mainGroup, x0, display.contentHeight / 4, 12 * half, 12 * half, 12)
	nextPieceArea:setFillColor(1, 1, 1)

	storedPieceArea = display.newRoundedRect(mainGroup, x0, 3 * display.contentHeight / 4, 12 * half, 12 * half, 12)
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
			local grid = display.newRect(line, x0 - 5 * half + (2 * row - 1) * half, display.contentHeight / 4 - 5 * half + (2 * col - 1) * half, 2 * half, 2 * half)
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
			local grid = display.newRect(line, x0 - 5 * half + (2 * row - 1) * half, 3 * display.contentHeight / 4 - 5 * half + (2 * col - 1) * half, 2 * half, 2 * half)
			grid:setStrokeColor(0.5, 0.5, 0.5, 0.8)
			grid.strokeWidth = half / 30
		end
		storedPieceGroup:insert(line)
	end

	uiGroup = display.newGroup()
	sceneGroup:insert(uiGroup)

	local nextPieceText = display.newText({
		parent = uiGroup,
		text = "NEXT",
		x = x0,
		y = display.contentHeight / 4 - 8 * half,
		font = native.systemFont,
		fontSize = 50,
		align = "center"
	})
	nextPieceText:setFillColor(0, 0, 0)

	local storedPieceText = display.newText({
		parent = uiGroup,
		text = "STORAGE",
		x = x0,
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
