
local composer = require( "composer" )

local scene = composer.newScene()

-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------

local const = require("constants")

local WIDTH = display.contentWidth
local HEIGHT = display.contentHeight
local half = HEIGHT / 40

local mainGroup
local boardGroup
local pauseGroup
local gameOverGroup

local gameOverTitle
local replayButton
local backMainButton

local keyboard = {}

local board
local count
local lines
local level
local isDone

local p =
{
	{ -- P1
		nextPieceGroup,
		storedPieceGroup,
	},
	{ -- P2
		nextPieceGroup,
		storedPieceGroup,
	}
}

local function scanBoard()
	for y = 0, 20 do
		count[y] = 0
		for x = 1, 16 do
			if (y == 0) then print("board[" .. y .. "][" .. x .. "]: " .. board[y][x]) end
			if (board[y][x] < 8) then count[y] = count[y] + 1 end
		end
	end
end

local function willBeCollide(player, x1, y1)
	for i = 1, 4 do
		local x0 = p[3 - player].pos.x + p[3 - player].piece[2 * i - 1]
		local y0 = p[3 - player].pos.y + p[3 - player].piece[2 * i]
		if (x1 == x0 and y1 == y0) then return true end
	end
	return false
end

local function setPiece(player)
	for i = 1, 4 do
		board[p[player].pos.y + p[player].piece[2 * i]][p[player].pos.x + p[player].piece[2 * i - 1]] = player
	end
end

local function checkGhost(player)
	for i = 1, 4 do
		local x0 = p[player].pos.x + p[player].piece[2 * i - 1]
		local y0 = p[player].ghostY + p[player].piece[2 * i]
		if (y0 > 20 or board[y0][x0] < 8) then return false end
	end
	return true
end

local function paintGhost(player, flag)
	if (flag == true) then
		p[player].ghostY = p[player].pos.y + 1
		while (checkGhost(player) == true) do p[player].ghostY = p[player].ghostY + 1 end
		p[player].ghostY = p[player].ghostY - 1
	end
	local rgb = const.color[flag and player or 8]
	for i = 1, 4 do
		if (p[player].ghostY + p[player].piece[2 * i] > 0) then
			boardGroup[p[player].ghostY + p[player].piece[2 * i]][p[player].pos.x + p[player].piece[2 * i - 1]]:setFillColor(rgb[1], rgb[2], rgb[3], flag and 0.2 or 1)
		end
	end
end

local function createPiece(player)
	for i = 0, 8 do p[player].piece[i] = const.pieces[p[player].nowPieceId][i] end
	if (player == 1) then p[1].pos.x = 4 else p[2].pos.x = 13 end
	p[player].pos.y = 0
end

local function paintNowPiece(player, flag)
	local rgb = const.color[flag and player or 8]
	for i = 1, 4 do
		if (p[player].pos.y + p[player].piece[2 * i] > 0) then
			boardGroup[p[player].pos.y + p[player].piece[2 * i]][p[player].pos.x + p[player].piece[2 * i - 1]]:setFillColor(rgb[1], rgb[2], rgb[3], 1)
		end
	end
end

local function paintNextPiece(player, flag)
	local rgb = const.color[flag and player or 8]
	for i = 1, 4 do
		p[player].nextPieceGroup[3 + const.pieces[p[player].nextPieceId][2 * i]][3 + const.pieces[p[player].nextPieceId][2 * i - 1]]:setFillColor(rgb[1], rgb[2], rgb[3])
	end
end

local function paintStoredPiece(player, flag)
	local rgb = const.color[flag and player or 8]
	for i = 1, 4 do
		p[player].storedPieceGroup[3 + const.pieces[p[player].storedPieceId][2 * i]][3 + const.pieces[p[player].storedPieceId][2 * i - 1]]:setFillColor(rgb[1], rgb[2], rgb[3])
	end
end

local function rearrangeBoard()
	local temp = {}
	for i = 1, 20 do temp[i] = i end
	for y = 20, 1, -1 do
		if (count[y] == 16) then table.remove(temp, y) end
	end
	for i = 0, #temp - 1 do
		count[#count - i] = count[temp[#temp - i]]
		for x = 1, 16 do
			board[#count - i][x] = board[temp[#temp - i]][x]
		end
	end
	for i = 1, #count - #temp do
		count[i] = 0
		for x = 1, 16 do board[i][x] = 8 end
	end
	for y = 1, 20 do
		for x = 1, 16 do
			local rgb = const.color[board[y][x]]
			boardGroup[y][x]:setFillColor(rgb[1], rgb[2], rgb[3])
		end
	end
	paintGhost(1, true)
	paintGhost(2, true)
	paintNowPiece(3 - player, true)
end

local function getRandomPiece(player)
	paintNextPiece(player, false)
	if (#p[player].bag == 0) then
		for i = 1, 7 do
			p[player].bag[i] = i
			p[player].box[i] = math.random(49)
		end
		table.sort(p[player].bag, function(a, b) return p[player].box[a] > p[player].box[b] end)
	end
	p[player].nowPieceId = p[player].nextPieceId
	p[player].nextPieceId = table.remove(p[player].bag)
	paintNextPiece(player, true)
end

local function move(player, dx, dy, arr)
	local temp = {}
	for i = 0, 8 do temp[i] = arr and arr[i] or p[player].piece[i] end
	for i = 1, 4 do
		local x = p[player].pos.x + dx + temp[2 * i - 1]
		local y = p[player].pos.y + dy + temp[2 * i]
		if (y > 20 or x < 1 or x > 16 or board[y][x] < 8 or willBeCollide(player, x, y)) then return false end
	end
	for i = 0, 8 do p[player].piece[i] = temp[i] end
	p[player].pos.x = p[player].pos.x + dx
	p[player].pos.y = p[player].pos.y + dy
	return true
end

local function rotate(player, clockwise)
	local temp = {[0] = p[player].piece[0]}
	for i = 1, 4 do
		if (clockwise > 0) then
			temp[2 * i - 1] = -p[player].piece[2 * i]
			temp[2 * i] = p[player].piece[2 * i - 1]
		else
			temp[2 * i - 1] = p[player].piece[2 * i]
			temp[2 * i] = -p[player].piece[2 * i - 1]
		end
	end

	local test = {}
	if (p[player].nowPieceId == 1) then
		if (clockwise > 0) then
			if (temp[0] == 0) then test = { 1,0, -1,0, 2,0, -1,1, 2,-2 }
			elseif (temp[0] == 1) then test = { 0,1, -1,1, 2,1, -1,-1, 2,2 }
			elseif (temp[0] == 2) then test = { -1,0, 1,0, -2,0, 1,-1, -2,2 }
			else test = { 0,-1, 1,-1, -2,-1, 1,1, -2,-2 } end
		else
			if (temp[0] == 0) then test = { 0,1, -1,1, 2,1, -1,-1, 2,2 }
			elseif (temp[0] == 1) then test = { -1,0, 1,0, -2,0, 1,-1, -2,2 }
			elseif (temp[0] == 2) then test = { 0,-1, 1,-1, -2,-2, 1,1, -2,-2 }
			else test = { 1,0, -1,0, 2,0, -1,1, 2,-2 } end
		end
	elseif (p[player].nowPieceId == 2) then
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
		if (move(player, test[2 * i - 1], test[2 * i], temp)) then return true end
	end
	return false
end

local function onCommonKeyEvent(event)
	if (gameOverGroup.isVisible == false and event.phase == "down") then
		if (event.keyName == "escape") then
			if (pauseGroup.isVisible == true) then
				pauseGroup.isVisible = false
				p[1].interval = p[1].pauseAt
				p[2].interval = p[2].pauseAt
			else
				p[1].pauseAt, p[1].interval = p[1].interval, -1
				p[2].pauseAt, p[2].interval = p[2].interval, -1
				pauseGroup.isVisible = true
			end
		end
	end
end

local function onKeyEvent(event, player)
	if (gameOverGroup.isVisible == false and pauseGroup.isVisible == false) then
		if (event.phase == "down") then
			if (event.keyName == const.config[player].hold and p[player].changePiece == false) then
				paintStoredPiece(player, false)
				paintNowPiece(player, false)
				paintGhost(player, false)
				p[player].nowPieceId, p[player].storedPieceId = p[player].storedPieceId, p[player].nowPieceId
				p[player].pos.x, p[player].pos.y = player == 1 and 4 or 13, 0
				p[player].changePiece = true
				for i = 0, 8 do p[player].piece[i] = const.pieces[p[player].nowPieceId][i] end
				paintGhost(player, true)
				paintNowPiece(player, true)
				paintStoredPiece(player, true)
			end
			if (event.keyName == const.config[player].hard) then
				paintNowPiece(player, false)
				paintGhost(player, false)
				p[player].pos.y = p[player].ghostY
				p[player].spin = false
				p[player].interval = 15
				paintGhost(player, true)
				paintNowPiece(player, true)
			end
			if (event.keyName == const.config[player].cw0 or event.keyName == const.config[player].cw) then
				paintNowPiece(player, false)
				paintGhost(player, false)
				p[player].spin = rotate(player, 1)
				paintGhost(player, true)
				paintNowPiece(player, true)
			end
			if (event.keyName == const.config[player].ccw) then
				paintNowPiece(player, false)
				paintGhost(player, false)
				p[player].spin = rotate(player, -1)
				paintGhost(player, true)
				paintNowPiece(player, true)
			end
			if (event.keyName == const.config[player].right or event.keyName == const.config[player].left or event.keyName == const.config[player].soft) then
				p[player].delay = 1
				keyboard[event.keyName] = true
			end
		elseif (event.keyName == const.config[player].right or event.keyName == const.config[player].left or event.keyName == const.config[player].soft) then
			keyboard[event.keyName] = false
		end
	end
end

local function onKeepPressEvent(player)

	p[player].delay = p[player].delay - 1

	if (p[player].delay == 0) then

		if keyboard[const.config[player].soft] then
			paintNowPiece(player, false)
			paintGhost(player, false)
			move(player, 0, 1)
			p[player].spin = false
			if (p[player].pos.y == p[player].ghostY) then p[player].interval = 15 end
			paintGhost(player, true)
			paintNowPiece(player, true)
		end

		if keyboard[const.config[player].right] then
			paintNowPiece(player, false)
			paintGhost(player, false)
			move(player, 1, 0)
			p[player].spin = false
			paintGhost(player, true)
			paintNowPiece(player, true)
		end

		if keyboard[const.config[player].left] then
			paintNowPiece(player, false)
			paintGhost(player, false)
			move(player, -1, 0)
			p[player].spin = false
			paintGhost(player, true)
			paintNowPiece(player, true)
		end

		p[player].delay = 5 - math.floor((level - 1) / 6)
	end
end

local function onFrameEvent(player)

	if (p[player].interval > 0) then
		p[player].interval = p[player].interval - 1
	end

	if (isDone == true and gameOverGroup.isVisible == false) then
		p[1].interval = -1
		p[2].interval = -1
		gameOverTitle.text = level > 15 and "Game Clear" or "Game Over"
--		finalP1LevelText.text = p[1].level
--		finalP2LevelText.text = p[2].level
--		finalP1LinesText.text = p[1].lines
--		finalP2LinesText.text = p[2].lines
--		finalP1ScoreText.text = p[1].score
--		finalP2ScoreText.text = p[2].score
		gameOverGroup.isVisible = true
	elseif (p[player].interval == 0) then
		paintNowPiece(player, false)
		if (move(player, 0, 1) == false) then
			paintGhost(player, false)
			if (p[player].nowPieceId < 8) then setPiece(player) end
			p[player].changePiece = false
			scanBoard()
			if (count[0] > 0) then
				isDone = true
			else
				getRandomPiece(player)
				createPiece(player)
				rearrangeBoard()
--				paintGhost(player, true)
			end
		end

		paintNowPiece(player, true)

		if (lines >= 10 * level) then level = level + 1 end

		if (level > 15) then
			isDone = true
		elseif (p[player].pos.y == p[player].ghostY) then
			p[player].interval = 15
		else 
			p[player].interval = 31 - level
		end
	end
end



local function initVariables()
	for player = 1, 2 do
		p[player].ghostY = 20
		p[player].pos = {x = player == 1 and 4 or 13, y = 20}
		p[player].piece = { [0] = 0, 0,0, 0,0, 0,0, 0,0 }
		p[player].box = {}
		p[player].bag = {}
		p[player].nowPieceId = 8
		p[player].nextPieceId = 8
		p[player].storedPieceId = 3
		p[player].changePiece = false
		p[player].interval = 1
		p[player].delay = 1
		p[player].pauseAt = -1
	end
	board = {}
	count = {}
	lines = 0
	level = 1
	isDone = false
end

local function initPiece()
	for y = -2, 20 do
		board[y] = {}
		for x = 1, 16 do board[y][x] = 8 end
	end
	for player = 1, 2 do
		getRandomPiece(player)
		paintStoredPiece(player, true)
	end
end

local function replay(event)
	if (event.isPrimaryButtonDown) then
		gameOverGroup.isVisible = false
		paintNextPiece(1, false)
		paintNextPiece(2, false)
		paintStoredPiece(1, false)
		paintStoredPiece(2, false)
		initVariables()
		initPiece()
	end
end

local function backToMain(event)
	if (event.isPrimaryButtonDown) then composer.gotoScene("title") end
end

local function onP1KeyEvent(event) onKeyEvent(event, 1) end
local function onP2KeyEvent(event) onKeyEvent(event, 2) end
local function onP1KeepPressEvent() onKeepPressEvent(1) end
local function onP2KeepPressEvent() onKeepPressEvent(2) end
local function onP1FrameEvent() onFrameEvent(1) end
local function onP2FrameEvent() onFrameEvent(2) end

-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------

-- create()
function scene:create( event )

	local sceneGroup = self.view
	-- Code here runs when the scene is first created but has not yet appeared on screen

	mainGroup = display.newGroup()
	sceneGroup:insert(mainGroup)

	local background = display.newRect(mainGroup, WIDTH / 2, HEIGHT / 2, WIDTH, HEIGHT)
	background:setFillColor(251 / 255, 206 / 255, 177 / 255, 0.8)

	local boardArea = display.newRect(mainGroup, WIDTH / 2, HEIGHT / 2, 32 * half, 40 * half)

	local p1NextPieceArea = display.newRoundedRect(mainGroup, WIDTH / 4 - 8 * half, HEIGHT / 4, 12 * half, 12 * half, 12)
	local p1StoredPieceArea = display.newRoundedRect(mainGroup, WIDTH / 4 - 8 * half, 3 * HEIGHT / 4, 12 * half, 12 * half, 12)

	local p1NextPieceString = display.newText({
		parent = mainGroup,
		text = "NEXT",
		x = WIDTH / 4 - 8 * half,
		y = HEIGHT / 4 - 8 * half,
		font = native.systemFont,
		fontSize = 50,
		align = "center"
	})
	p1NextPieceString:setFillColor(0, 0, 0)

	local p1String = display.newText({
		parent = mainGroup,
		text = "P1",
		x = WIDTH / 4 - 8 * half,
		y = HEIGHT / 2,
		font = native.systemFont,
		fontSize = 75,
		align = "center"
	})
	p1String:setFillColor(0, 0, 1)

	local p1StoredPieceString = display.newText({
		parent = mainGroup,
		text = "HOLD",
		x = WIDTH / 4 - 8 * half,
		y = 3 * HEIGHT / 4 + 8 * half,
		font = native.systemFont,
		fontSize = 50,
		align = "center"
	})
	p1StoredPieceString:setFillColor(0, 0, 0)

	local p2NextPieceArea = display.newRoundedRect(mainGroup, 3 * WIDTH / 4 + 8 * half, HEIGHT / 4, 12 * half, 12 * half, 12)
	local p2StoredPieceArea = display.newRoundedRect(mainGroup, 3 * WIDTH / 4 + 8 * half, 3 * HEIGHT / 4, 12 * half, 12 * half, 12)

	local p2NextPieceString = display.newText({
		parent = mainGroup,
		text = "NEXT",
		x = 3 * WIDTH / 4 + 8 * half,
		y = HEIGHT / 4 - 8 * half,
		font = native.systemFont,
		fontSize = 50,
		align = "center"
	})
	p2NextPieceString:setFillColor(0, 0, 0)

	local p2String = display.newText({
		parent = mainGroup,
		text = "P2",
		x = 3 * WIDTH / 4 + 8 * half,
		y = HEIGHT / 2,
		font = native.systemFont,
		fontSize = 75,
		align = "center"
	})
	p2String:setFillColor(1, 0, 0)

	local p2StoredPieceString = display.newText({
		parent = mainGroup,
		text = "HOLD",
		x = 3 * WIDTH / 4 + 8 * half,
		y = 3 * HEIGHT / 4 + 8 * half,
		font = native.systemFont,
		fontSize = 50,
		align = "center"
	})
	p2StoredPieceString:setFillColor(0, 0, 0)

	boardGroup = display.newGroup()
	sceneGroup:insert(boardGroup)

	for y = 1, 20 do
		local line = display.newGroup()
		for x = 1, 16 do
			local grid = display.newRect(line, (WIDTH / 2 - 16 * half) + (2 * x - 1) * half, (2 * y - 1) * half, 2 * half, 2 * half)
			grid:setStrokeColor(0.5, 0.5, 0.5, 0.8)
			grid.strokeWidth = half / 30
		end
		boardGroup:insert(line)
	end

	p[1].nextPieceGroup = display.newGroup()
	sceneGroup:insert(p[1].nextPieceGroup)

	for y = 1, 5 do
		local line = display.newGroup()
		for x = 1, 5 do
			local grid = display.newRect(line, (WIDTH / 4 - 13 * half) + (2 * x - 1) * half, (HEIGHT / 4 - 5 * half) + (2 * y - 1) * half, 2 * half, 2 * half)
			grid:setStrokeColor(0.5, 0.5, 0.5, 0.8)
			grid.strokeWidth = half / 30
		end
		p[1].nextPieceGroup:insert(line)
	end

	p[1].storedPieceGroup = display.newGroup()
	mainGroup:insert(p[1].storedPieceGroup)

	for y = 1, 5 do
		local line = display.newGroup()
		for x = 1, 5 do
			local grid = display.newRect(line, (WIDTH / 4 - 13 * half) + (2 * x - 1) * half, (3 * HEIGHT / 4 - 5 * half) + (2 * y - 1) * half, 2 * half, 2 * half)
			grid:setStrokeColor(0.5, 0.5, 0.5, 0.8)
			grid.strokeWidth = half / 30
		end
		p[1].storedPieceGroup:insert(line)
	end

	p[2].nextPieceGroup = display.newGroup()
	sceneGroup:insert(p[2].nextPieceGroup)

	for y = 1, 5 do
		local line = display.newGroup()
		for x = 1, 5 do
			local grid = display.newRect(line, (3 * WIDTH / 4 + 3 * half) + (2 * x - 1) * half, (HEIGHT / 4 - 5 * half) + (2 * y - 1) * half, 2 * half, 2 * half)
			grid:setStrokeColor(0.5, 0.5, 0.5, 0.8)
			grid.strokeWidth = half / 30
		end
		p[2].nextPieceGroup:insert(line)
	end

	p[2].storedPieceGroup = display.newGroup()
	mainGroup:insert(p[2].storedPieceGroup)

	for y = 1, 5 do
		local line = display.newGroup()
		for x = 1, 5 do
			local grid = display.newRect(line, (3 * WIDTH / 4 + 3 * half) + (2 * x - 1) * half, (3 * HEIGHT / 4 - 5 * half) + (2 * y - 1) * half, 2 * half, 2 * half)
			grid:setStrokeColor(0.5, 0.5, 0.5, 0.8)
			grid.strokeWidth = half / 30
		end
		p[2].storedPieceGroup:insert(line)
	end

	pauseGroup = display.newGroup()
	sceneGroup:insert(pauseGroup)
	pauseGroup.isVisible = false

	local pauseBackground = display.newRect(pauseGroup, WIDTH / 2, HEIGHT / 2, WIDTH, HEIGHT)
	pauseBackground:setFillColor(1, 1, 1, 0.4)

	local pauseImg = display.newImageRect(pauseGroup, "pause.png", HEIGHT / 2, HEIGHT / 2)
	pauseImg.x = WIDTH / 2
	pauseImg.y = HEIGHT / 2
	pauseImg.alpha = 0.8

	gameOverGroup = display.newGroup()
	sceneGroup:insert(gameOverGroup)
	gameOverGroup.isVisible = false

	local gameOverBackground = display.newRect(gameOverGroup, WIDTH / 2, HEIGHT / 2, WIDTH, HEIGHT)
	gameOverBackground:setFillColor(0, 0, 0, 0.8)

	local gameOverAlert = display.newRoundedRect(gameOverGroup, WIDTH / 2, HEIGHT / 2, WIDTH / 2, WIDTH / 2, 20)
	gameOverAlert:setFillColor(1, 1, 1, 0.8)
	gameOverAlert.alpha = 0.8

	gameOverTitle = display.newText({
		parent = gameOverGroup,
		text = "Lorem Ipsum",
		x = WIDTH / 2 ,
		y = HEIGHT / 2 - 3 * WIDTH / 16,
		font = native.systemFont,
		fontSize = 75,
		align = "center"
	})
	gameOverTitle:setFillColor(0, 0, 0)

	initVariables()
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

--		replayButton:addEventListener("mouse", replay)
--		backMainButton:addEventListener("mouse", backToMain)
		Runtime:addEventListener("key", onCommonKeyEvent)
		Runtime:addEventListener("key", onP1KeyEvent)
		Runtime:addEventListener("key", onP2KeyEvent)
		Runtime:addEventListener("enterFrame", onP1KeepPressEvent)
		Runtime:addEventListener("enterFrame", onP2KeepPressEvent)
		Runtime:addEventListener("enterFrame", onP1FrameEvent)
		Runtime:addEventListener("enterFrame", onP2FrameEvent)

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
		
		Runtime:removeEventListener("key", onCommonKeyEvent)
		Runtime:removeEventListener("key", onP1KeyEvent)
		Runtime:removeEventListener("key", onP2KeyEvent)
		Runtime:removeEventListener("enterFrame", onP1KeepPressEvent)
		Runtime:removeEventListener("enterFrame", onP2KeepPressEvent)
		Runtime:removeEventListener("enterFrame", onP1FrameEvent)
		Runtime:removeEventListener("enterFrame", onP2FrameEvent)
		composer.removeScene("coop")
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
