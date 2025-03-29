
local composer = require( "composer" )

local scene = composer.newScene()

-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------

local WIDTH = display.contentWidth
local HEIGHT = display.contentHeight

local action
local delay

local backGroup
local mainGroup
-- local lineGroup
local uiGroup
local pauseGroup
local gameOverGroup

local levelVarText
local linesVarText
local scoreVarText

local gameOverTitle
local finalScoreText

local replayButton
local backMainButton

local board
local isEmpty

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
	{ [0] = 0, -1,0, 0,0, 1,0, 2,0 },		-- I
	{ [0] = 0, 0,-1, 1,-1, 0,0, 1,0 },		-- O
	{ [0] = 0, -1,0, 0,0, 0,-1, 1,0 },		-- T
	{ [0] = 0, -1,-1, -1,0, 0,0, 1,0 },		-- J
	{ [0] = 0, -1,0, 0,0, 1,0, 1,-1 },		-- L
	{ [0] = 0, -1,0, 0,0, 0,-1, 1,-1 },		-- S
	{ [0] = 0, -1,-1, 0,-1, 0,0, 1,0 },		-- Z
	{ [0] = 0, 0,0, 0,0, 0,0, 0,0 },		-- dummy
}

local ghostY
local pos
local piece

local box
local bag

local gameBoardGroup
local nextPieceGroup
local storedPieceGroup

local nowPieceId
local nextPieceId
local storedPieceId

local changePiece
local isFalling

local remain
local line
local level
local score

local pauseAt
local isComplete

local function checkGhost()
	for i = 1, 4 do
		local x0 = pos.x + piece[2 * i - 1]
		local y0 = ghostY + piece[2 * i]
		print("x0: " .. x0 .. ", y0: " .. y0 .. ", ghostY: " .. ghostY)
		if (y0 > 20 or board[y0][x0] < 8) then return false end
	end
	return true
end

local function paintGhost(flag)
	if (flag == true) then
		ghostY = pos.y + 1
		while (checkGhost() == true) do ghostY = ghostY + 1 end
		ghostY = ghostY - 1
	end
	local rgb = color[flag == true and nowPieceId or 8]
	for i = 1, 4 do
		if (ghostY + piece[2 * i] > 0) then
			gameBoardGroup[ghostY + piece[2 * i]][pos.x + piece[2 * i - 1]]:setFillColor(rgb[1], rgb[2], rgb[3], flag and 0.2 or 1)
		end
	end
end

local function paintNowPiece(flag)
	local rgb = color[flag == true and nowPieceId or 8]
	for i = 1, 4 do
		if (pos.y + piece[2 * i] > 0) then
			gameBoardGroup[pos.y + piece[2 * i]][pos.x + piece[2 * i - 1]]:setFillColor(rgb[1], rgb[2], rgb[3], 1)
		end
	end
end

local function backToMain(event)
	if (event.isPrimaryButtonDown) then composer.gotoScene("title") end
end

local function isGameOver()
	for row = 1, 10 do
		if (board[0][row] < 8) then return true end
	end
	return false
end

local function scanBoard()
	for col = 1, 20 do
		local count = 0
		for row = 1, 10 do
			if (board[col][row] < 8) then count = count + 1 end
		end
		if (count == 10) then
			line = line + 1
			count = 0
		end
		isEmpty[col] = (count == 0)
	end
	linesVarText.text = line
end

local function rearrangeBoard()
	for down = 20, 1, -1 do
		if (isEmpty[down] == true) then
			for up = down - 1, 1, -1 do
				if (isEmpty[up] == false) then
					for row = 1, 10 do
						board[down][row] = board[up][row]
						board[up][row] = 8
					end
					isEmpty[down], isEmpty[up] = false, true
					break
				end
			end
		end
	end
end

local function paintBoard()
	for col = 1, 20 do
		for row = 1, 10 do
			local rgb = color[board[col][row]]
			gameBoardGroup[col][row]:setFillColor(rgb[1], rgb[2], rgb[3])
		end
	end
end

local function paintNextPiece(flag)
	local rgb = color[flag == true and nextPieceId or 8]
	for i = 1, 4 do
		nextPieceGroup[3 + pieces[nextPieceId][2 * i]][3 + pieces[nextPieceId][2 * i - 1]]:setFillColor(rgb[1], rgb[2], rgb[3])
	end
end

local function paintStoredPiece(flag)
	local rgb = color[flag == true and storedPieceId or 8]
	for i = 1, 4 do
		storedPieceGroup[3 + pieces[storedPieceId][2 * i]][3 + pieces[storedPieceId][2 * i - 1]]:setFillColor(rgb[1], rgb[2], rgb[3])
	end
end

local function getRandomPiece()
	paintNextPiece(false)
	if (#bag == 0) then
		for i = 1, 7 do
			bag[i] = i
			box[i] = math.random(49)
		end
		table.sort(bag, function(a, b) return box[a] > box[b] end)
	end
	nowPieceId = nextPieceId
	nextPieceId = table.remove(bag)
	paintNextPiece(true)
end

local function setPiece()
	for i = 1, 4 do
		board[pos.y + piece[2 * i]][pos.x + piece[2 * i - 1]] = nowPieceId
	end
end

local function move(dx, dy, arr)
	local temp = {}
	for i = 0, 8 do temp[i] = arr and arr[i] or piece[i] end
	for i = 1, 4 do
		local x0 = pos.x + dx + temp[2 * i - 1]
		local y0 = pos.y + dy + temp[2 * i]
		if (y0 > 20 or x0 < 1 or x0 > 10 or board[y0][x0] < 8) then return false end
	end
	for i = 0, 8 do piece[i] = temp[i] end
	pos.x, pos.y = pos.x + dx, pos.y + dy
	return true
end

local function rotate(clockwise)
	local temp = {[0] = piece[0]}
	for i = 1, 4 do
		if (clockwise == true) then
			temp[2 * i - 1], temp[2 * i] = piece[2 * i], -piece[2 * i - 1]
		else
			temp[2 * i - 1], temp[2 * i] = -piece[2 * i], piece[2 * i - 1]
		end
	end

	local test = {}
	if (nowPieceId == 1) then
		if (clockwise > 0) then
			if (temp[0] == 0) then test = { 0,0, -2,0, 1,0, -2,1, 1,-2 }
			elseif (temp[0] == 1) then test = { 0,0, -1,0, 2,0, -1,-2, 2,1 }
			elseif (temp[0] == 2) then test = { 0,0, 2,0, -1,0, 2,-1, -1,2 }
			else test = { 0,0, 1,0, -2,0, 1,2, -2,-1 } end
		else
			if (temp[0] == 0) then test = { 0,0, -1,0, 2,0, -1,-2, 2,1 }
			elseif (temp[0] == 1) then test = { 0,0, 2,0, -1,0, 2,-1, -1,2 }
			elseif (temp[0] == 2) then test = { 0,0, 1,0, -2,0, 1,2, -2,-1 }
			else test = { 0,0, -2,0, 1,0, -2,1, 1,-2 } end
		end
	elseif (nowPieceId == 2) then
		if (clockwise > 0) then
			if (temp[0] == 0) then test = { 0,-1 }
			elseif (temp[0] == 1) then test = { 1,0 }
			elseif (temp[0] == 2) then test = { 0,1 }
			else test = { -1,0 } end
		else
			if (temp[0] == 0) then test = { 1,0 }
			elseif (temp[0] == 1) then test = { 0,1 }
			elseif (temp[0] == 2) then test = { -1,0 }
			else test = { 0,-1 } end
		end
	else
		if (clockwise > 0) then
			if (temp[0] == 0) then test = { 0,0, -1,0, -1,-1, 0,2, -1,2 }
			elseif (temp[0] == 1) then test = { 0,0, 1,0, 1,1, 0,-2, 1,-2 }
			elseif (temp[0] == 2) then test = { 0,0, 1,0, 1,-1, 0,2, 1,2 }
			else test = { 0,0, -1,0, -1,1, 0,-2, -1,-2 } end
		else
			if (temp[0] == 0) then test = { 0,0, 1,0, 1,-1, 0,2, 1,2 }
			elseif (temp[0] == 1) then test = { 0,0, 1,0, 1,1, 0,-2, 1,-2 }
			elseif (temp[0] == 2) then test = { 0,0, -1,0, -1,-1, 0,2, -1,2 }
			else test = { 0,0, -1,0, -1,1, 0,-2, -1,-2 } end
		end
	end

	temp[0] = (temp[0] + clockwise) % 4
	for i = 1, 5 do
		if (move(test[2 * i - 1], test[2 * i], temp)) then return true end
	end
	return false
end

local function onKeyEvent(event)
	if (gameOverGroup.isVisible == false) then
		if (event.phase == "down") then
			if (event.keyName == "down" or event.keyName == "left" or event.keyName == "right") then
				action[event.keyName] = true
			elseif (event.keyName == "escape") then
				if (isFalling == true) then
					if (remain > 0) then
						pauseAt, remain = remain, -1
						pauseGroup.isVisible = true
					else
						pauseGroup.isVisible = false
						remain = pauseAt
					end
				end
			elseif (event.keyName == "leftShift" or event.keyName == "c") then
				if (isFalling == true and changePiece == false) then
					paintNowPiece(false)
					paintGhost(false)
					paintStoredPiece(false)
					nowPieceId, storedPieceId = storedPieceId, nowPieceId
					pos.x, pos.y = 5, 0
					changePiece = true
					for i = 0, 8 do piece[i] = pieces[nowPieceId][i] end
					paintStoredPiece(true)
					paintGhost(true)
					paintNowPiece(true)
				end
			elseif (event.keyName == "space") then
				if (isFalling == true) then
					paintNowPiece(false)
					paintGhost(false)
					while (move(0, 1) == true) do end
					paintGhost(true)
					paintNowPiece(true)
				end
			elseif (event.keyName == "up") then
				paintNowPiece(false)
				paintGhost(false)
				rotate(1)
				paintGhost(true)
				paintNowPiece(true)
			elseif (event.keyName == "leftCtrl" or event.keyName == "z") then
				paintNowPiece(false)
				paintGhost(false)
				rotate(-1)
				paintGhost(true)
				paintNowPiece(true)
			end
		elseif (event.keyName == "down" or event.keyName == "left" or event.keyName == "right") then
			action[event.keyName] = false
		end
	end
end

local function handleKeyboard()

	delay = delay - 1

	if (delay == 0) then
		if action["down"] then
			paintNowPiece(false)
			paintGhost(false)
			move(0, 1)
			paintGhost(true)
			paintNowPiece(true)
		end
		if action["left"] then
			paintNowPiece(false)
			paintGhost(false)
			move(-1, 0)
			paintGhost(true)
			paintNowPiece(true)
		end
		if action["right"] then
			paintNowPiece(false)
			paintGhost(false)
			move(1, 0)
			paintGhost(true)
			paintNowPiece(true)
		end
		delay = 3
	end
end

local function onFrameEvent()

	remain = remain - 1

	if (level == 31) then
		gameOverTitle.text = isComplete and "Game Clear" or "Game Over"
		finalScoreText.text = score
		gameOverGroup.isVisible = true
	elseif (remain == 0) then
		paintNowPiece(false)
		if (move(0, 1) == false) then
			paintGhost(false)
			setPiece()
--			paintNowPiece(true)
			isFalling = false
			changePiece = false
			scanBoard()
			if (isGameOver() == true) then
				isComplete = false
				level = 31
			else
				rearrangeBoard()
				paintBoard()
				getRandomPiece()
				for i = 0, 8 do piece[i] = pieces[nowPieceId][i] end
				pos.x, pos.y = 5, 0
				paintGhost(true)
			end
		end

		if (line >= 5 * level) then
			level = level + 1
			levelVarText.text = level
		end

		paintNowPiece(true)
		remain = 31 - level
		isFalling = true
	end
end

local function initVariables()
	action = {}
	delay = 1
	board = {[-2] = {8, 8, 8, 8, 8, 8, 8, 8, 8, 8}, [-1] = {8, 8, 8, 8, 8, 8, 8, 8, 8, 8}, [0] = {8, 8, 8, 8, 8, 8, 8, 8, 8, 8}}
	isEmpty = {}
	ghostY = 20
	pos = {x = 5, y = 20}
	piece = { [0] = 0, 0,0, 0,0, 0,0, 0,0 }
	box = {}
	bag = {}
	nowPieceId = 8
	nextPieceId = 8
	storedPieceId = 3
	changePiece = false
	isFalling = false
	remain = 1
	line = 0
	level = 1
	score = 0
	pauseAt = -1
	isComplete = true
end

local function initPiece()
	for col = 1, 20 do
		local arr = {}
		for row = 1, 10 do arr[row] = 8 end
		board[col] = arr
	end
	getRandomPiece()
	paintStoredPiece(true)
end

local function replay(event)
	if (event.isPrimaryButtonDown) then
		gameOverGroup.isVisible = false
		initVariables()
		initPiece()
	end
end

-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------

-- create()
function scene:create( event )

	local sceneGroup = self.view
	-- Code here runs when the scene is first created but has not yet appeared on screen

	initVariables()

	backGroup = display.newGroup()
	sceneGroup:insert(backGroup)

	local background = display.newRect(backGroup, WIDTH / 2, HEIGHT / 2, WIDTH, HEIGHT)
	background:setFillColor(251 / 255, 206 / 255, 177 / 255, 0.8)

	mainGroup = display.newGroup()
	sceneGroup:insert(mainGroup)

	local x1 = WIDTH / 4 - HEIGHT / 8
	local x2 = 3 * WIDTH / 4 + HEIGHT / 8
	local half = HEIGHT / 40

	local scoreBoardArea = display.newRoundedRect(mainGroup, x1, HEIGHT / 2, 20 * half, 20 * half, 12)
	scoreBoardArea:setFillColor(251 / 255, 206 / 255, 177 / 255, 0.8)
	scoreBoardArea:setStrokeColor(1, 1, 1)
	scoreBoardArea.strokeWidth = half / 2

	local scoreArea = display.newRoundedRect(mainGroup, x1 - 6 * half, HEIGHT / 2 - 5 * half, 7 * half, 3 * half, 2)
	scoreArea:setFillColor(203 / 255, 125 / 255, 96 / 255, 0.8)

	local scoreVarArea = display.newRoundedRect(mainGroup, x1 + 4 * half, HEIGHT / 2 - 5 * half, 10 * half, 3 * half, 2)
	scoreVarArea:setFillColor(203 / 255, 125 / 255, 96 / 255, 0.8)

	local levelArea = display.newRoundedRect(mainGroup, x1 - 6 * half, HEIGHT / 2, 7 * half, 3 * half, 2)
	levelArea:setFillColor(203 / 255, 125 / 255, 96 / 255, 0.8)

	local levelVarArea = display.newRoundedRect(mainGroup, x1 + 4 * half, HEIGHT / 2, 10 * half, 3 * half, 2)
	levelVarArea:setFillColor(203 / 255, 125 / 255, 96 / 255, 0.8)

	local remainArea = display.newRoundedRect(mainGroup, x1 - 6 * half, HEIGHT / 2 + 5 * half, 7 * half, 3 * half, 2)
	remainArea:setFillColor(203 / 255, 125 / 255, 96 / 255, 0.8)

	local remainVarArea = display.newRoundedRect(mainGroup, x1 + 4 * half, HEIGHT / 2 + 5 * half, 10 * half, 3 * half, 2)
	remainVarArea:setFillColor(203 / 255, 125 / 255, 96 / 255, 0.8)

	local nextPieceArea = display.newRoundedRect(mainGroup, x2, HEIGHT / 4, 12 * half, 12 * half, 12)
	nextPieceArea:setFillColor(1, 1, 1)

	local storedPieceArea = display.newRoundedRect(mainGroup, x2, 3 * HEIGHT / 4, 12 * half, 12 * half, 12)
	storedPieceArea:setFillColor(1, 1, 1)

--	lineClearGroup = display.newGroup()
--	mainGroup:insert(lineClearGroup)

--	for col = 1, 20 do
--		local line = display.newRect(lineClearGroup, WIDTH / 2, (2 * col - 1) * half, HEIGHT / 4, 2 * half)
--	end

	gameBoardGroup = display.newGroup()
	mainGroup:insert(gameBoardGroup)
	
	local start = WIDTH / 2 - HEIGHT / 4

	for col = 1, 20 do
		local line = display.newGroup()
		for row = 1, 10 do
			local grid = display.newRect(line, start + (2 * row - 1) * half, (2 * col - 1) * half, 2 * half, 2 * half)
			grid:setStrokeColor(0.5, 0.5, 0.5, 0.8)
			grid.strokeWidth = half / 30
		end
		gameBoardGroup:insert(line)
	end

	nextPieceGroup = display.newGroup()
	mainGroup:insert(nextPieceGroup)

	for col = 1, 5 do
		local line = display.newGroup()
		for row = 1, 5 do
			local grid = display.newRect(line, x2 - 5 * half + (2 * row - 1) * half, HEIGHT / 4 - 5 * half + (2 * col - 1) * half, 2 * half, 2 * half)
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
			local grid = display.newRect(line, x2 - 5 * half + (2 * row - 1) * half, 3 * HEIGHT / 4 - 5 * half + (2 * col - 1) * half, 2 * half, 2 * half)
			grid:setStrokeColor(0.5, 0.5, 0.5, 0.8)
			grid.strokeWidth = half / 30
		end
		storedPieceGroup:insert(line)
	end

	uiGroup = display.newGroup()
	sceneGroup:insert(uiGroup)

	local levelText = display.newText({
		parent = uiGroup,
		text = "LEVEL",
		x = x1 - 6 * half,
		y = HEIGHT / 2 - 5 * half,
		font = native.systemFont,
		fontSize = 30,
		align = "center"
	})
	levelText:setFillColor(0, 0, 0)

	levelVarText = display.newText({
		parent = uiGroup,
		text = "1",
		x = x1 + 4 * half,
		y = HEIGHT / 2 - 5 * half,
		font = native.systemFont,
		fontSize = 30,
		align = "right",
		width = 9 * half
	})
	levelVarText:setFillColor(0, 0, 0)

	local linesText = display.newText({
		parent = uiGroup,
		text = "LINES",
		x = x1 - 6 * half,
		y = HEIGHT / 2,
		font = native.systemFont,
		fontSize = 30,
		align = "center"
	})
	linesText:setFillColor(0, 0, 0)

	linesVarText = display.newText({
		parent = uiGroup,
		text = "0",
		x = x1 + 4 * half,
		y = HEIGHT / 2,
		font = native.systemFont,
		fontSize = 30,
		align = "right",
		width = 9 * half
	})
	linesVarText:setFillColor(0, 0, 0)

	local scoreText = display.newText({
		parent = uiGroup,
		text = "SCORE",
		x = x1 - 6 * half,
		y = HEIGHT / 2 + 5 * half,
		font = native.systemFont,
		fontSize = 30,
		align = "center"
	})
	scoreText:setFillColor(0, 0, 0)

	scoreVarText = display.newText({
		parent = uiGroup,
		text = "0",
		x = x1 + 4 * half,
		y = HEIGHT / 2 + 5 * half,
		font = native.systemFont,
		fontSize = 30,
		align = "right",
		width = 9 * half
	})
	scoreVarText:setFillColor(0, 0, 0)

	local nextPieceText = display.newText({
		parent = uiGroup,
		text = "NEXT",
		x = x2,
		y = HEIGHT / 4 - 8 * half,
		font = native.systemFont,
		fontSize = 50,
		align = "center"
	})
	nextPieceText:setFillColor(0, 0, 0)

	local storedPieceText = display.newText({
		parent = uiGroup,
		text = "HOLD",
		x = x2,
		y = 3 * HEIGHT / 4 - 8 * half,
		font = native.systemFont,
		fontSize = 50,
		align = "center"
	})
	storedPieceText:setFillColor(0, 0, 0)

	pauseGroup = display.newGroup()
	sceneGroup:insert(pauseGroup)

	local pauseBackground = display.newRect(pauseGroup, WIDTH / 2, HEIGHT / 2, WIDTH, HEIGHT)
	pauseBackground:setFillColor(1, 1, 1, 0.4)

	local pauseImg = display.newImageRect(pauseGroup, "pause.png", HEIGHT / 2, HEIGHT / 2)
	pauseImg.x = WIDTH / 2
	pauseImg.y = HEIGHT / 2
	pauseImg.alpha = 0.8

	gameOverGroup = display.newGroup()
	sceneGroup:insert(gameOverGroup)

	local gameOverBackground = display.newRect(gameOverGroup, WIDTH / 2, HEIGHT / 2, WIDTH, HEIGHT)
	gameOverBackground:setFillColor(0, 0, 0, 0.8)

	local gameOverAlert = display.newRoundedRect(gameOverGroup, WIDTH / 2, HEIGHT / 2, WIDTH / 2, WIDTH / 2, 20)
	gameOverAlert:setFillColor(1, 1, 1, 0.8)
	gameOverAlert.alpha = 0.8

	local finalScoreArea = display.newRoundedRect(gameOverGroup, 11 * WIDTH / 32, HEIGHT / 2, 12 * half, 4 * half, 10)
	finalScoreArea:setFillColor(251 / 255, 206 / 255, 177 / 255, 0.8)
	finalScoreArea.alpha = 0.8

	local finalScoreVarArea = display.newRoundedRect(gameOverGroup, 19 * WIDTH / 32, HEIGHT / 2, 16 * half, 4 * half, 10)
	finalScoreVarArea:setFillColor(251 / 255, 206 / 255, 177 / 255, 0.8)
	finalScoreVarArea.alpha = 0.8

	replayButton = display.newRoundedRect(gameOverGroup, 3 * WIDTH / 8, HEIGHT / 2 + WIDTH / 8, 16 * half, 6 * half, 10)
	replayButton:setFillColor(203 / 255, 125 / 255, 96 / 255, 0.8)
	replayButton.alpha = 0.8

	backMainButton = display.newRoundedRect(gameOverGroup, 5 * WIDTH / 8, HEIGHT / 2 + WIDTH / 8, 16 * half, 6 * half, 10)
	backMainButton:setFillColor(203 / 255, 125 / 255, 96 / 255, 0.8)
	backMainButton.alpha = 0.8

	gameOverTitle = display.newText({
		parent = gameOverGroup,
		text = "Lorem Ipsum",
		x = WIDTH / 2,
		y = HEIGHT / 2 - WIDTH / 8,
		font = native.systemFont,
		fontSize = 50,
		align = "center"
	})
	gameOverTitle:setFillColor(0, 0, 0)

	local finalScoreString = display.newText({
		parent = gameOverGroup,
		text = "SCORE",
		x = 11 * WIDTH / 32,
		y = HEIGHT / 2,
		font = native.systemFont,
		fontSize = 50,
		align = "center"
	})
	finalScoreString:setFillColor(0, 0, 0)

	finalScoreText = display.newText({
		parent = gameOverGroup,
		text = "Lorem Ipsum",
		x = 19 * WIDTH / 32,
		y = HEIGHT / 2,
		font = native.systemFont,
		fontSize = 50,
		align = "right"
	})
	finalScoreText:setFillColor(0, 0, 0)

	local replayText = display.newText({
		parent = gameOverGroup,
		text = "REPLAY",
		x = 3 * WIDTH / 8,
		y = HEIGHT / 2 + WIDTH / 8,
		font = native.systemFont,
		fontSize = 50,
		align = "center"
	})
	replayText:setFillColor(0, 0, 0)

	local backMainText = display.newText({
		parent = gameOverGroup,
		text = "MAIN",
		x = 5 * WIDTH / 8,
		y = HEIGHT / 2 + WIDTH / 8,
		font = native.systemFont,
		fontSize = 50,
		align = "center"
	})
	backMainText:setFillColor(0, 0, 0)

	pauseGroup.isVisible = false
	gameOverGroup.isVisible = false
	
	initPiece()
end


-- show()
function scene:show( event )

	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		-- Code here runs when the scene is still off screen (but is about to come on screen)

	elseif ( phase == "did" ) then
		-- Code here runs when the scene is entirely on screen

		replayButton:addEventListener("mouse", replay)
		backMainButton:addEventListener("mouse", backToMain)
		Runtime:addEventListener("key", onKeyEvent)
		Runtime:addEventListener("enterFrame", onFrameEvent)
		Runtime:addEventListener("enterFrame", handleKeyboard)
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

		Runtime:removeEventListener("key", onKeyEvent)
		Runtime:removeEventListener("enterFrame", onFrameEvent)
		composer.removeScene("single")
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
