
local composer = require( "composer" )

local scene = composer.newScene()

-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------

local const = require("constants")
-- local fun = require("functions")

local WIDTH = display.contentWidth
local HEIGHT = display.contentHeight
local half = HEIGHT / 40

local mainGroup
local pauseGroup
local gameOverGroup

local keyboard = {}
local queue = {}
local winner = 0

--[=[
1P		config		2P
J		left		numpad 4
L		right		numpad 6
K		soft drop	numpad 5
A		 90 rotate	left arrow
D		-90 rotate	right arrow
S		hard drop	down arrow
W		hold		up arrow
]=]--

local p =
{
	{ -- P1
		boardGroup,
		nextPieceGroup,
		storedPieceGroup,
		ghostY = 20,
		pos = {x = 5, y = 20},
		piece = { [0] = 0, 0,0, 0,0, 0,0, 0,0 },
		board = {[-2] = {8, 8, 8, 8, 8, 8, 8, 8, 8, 8}, [-1] = {8, 8, 8, 8, 8, 8, 8, 8, 8, 8}, [0] = {8, 8, 8, 8, 8, 8, 8, 8, 8, 8}},
		count = {},
		box = {},
		bag = {},
		nowPieceId = 8,
		nextPieceId = 8,
		storedPieceId = 1,
		changePiece = false,
		score = 0,
		lines = 0,
		level = 1,
		pauseAt = -1,
		interval = 1,
		delay = 1,
		cw0 = "i",
		right = "l",
		left = "j",
		soft = "k",
		hard = "s",
		cw = "d",
		ccw = "a",
		hold = "w",
	},
	{ -- P2
		boardGroup,
		nextPieceGroup,
		storedPieceGroup,
		ghostY = 20,
		pos = {x = 5, y = 20},
		piece = { [0] = 0, 0,0, 0,0, 0,0, 0,0 },
		board = {[-2] = {8, 8, 8, 8, 8, 8, 8, 8, 8, 8}, [-1] = {8, 8, 8, 8, 8, 8, 8, 8, 8, 8}, [0] = {8, 8, 8, 8, 8, 8, 8, 8, 8, 8}},
		count = {},
		box = {},
		bag = {},
		nowPieceId = 8,
		nextPieceId = 8,
		storedPieceId = 1,
		changePiece = false,
		score = 0,
		lines = 0,
		level = 1,
		pauseAt = -1,
		interval = 1,
		delay = -1,
		cw0 = "numPad8",
		right = "numPad6",
		left = "numPad4",
		soft = "numPad5",
		hard = "down",
		cw = "right",
		ccw = "left",
		hold = "up",
	}
}

local function isGameOver(player)
	for row = 1, 10 do
		if (p[player].board[0][row] < 8) then return true end
	end
	return false
end

local function scanBoard(player)
	for col = 1, 20 do
		p[player].count[col] = 0
		for row = 1, 10 do
			if (p[player].board[col][row] < 8) then p[player].count[col] = p[player].count[col] + 1 end
		end
	end
end

local function rearrangeBoard(player)
	local temp = {}
	for i = 1, 20 do temp[i] = i end
	for col = 20, 1, -1 do
		if (p[player].count[col] == 10) then table.remove(temp, col) end
	end
	for i = 0, #temp - 1 do
		p[player].board[#p[player].count - i] = p[player].board[temp[#temp - i]]
		p[player].count[#p[player].count - i] = p[player].count[temp[#temp - i]]
	end
	for i = 1, #p[player].count - #temp do
		p[player].board[i] = {8, 8, 8, 8, 8, 8, 8, 8, 8, 8}
		p[player].count[i] = 0
	end
end

local function setPiece(player)
	for i = 1, 4 do
		p[player].board[p[player].pos.y + p[player].piece[2 * i]][p[player].pos.x + p[player].piece[2 * i - 1]] = p[player].nowPieceId
	end
end

local function paintBoard(player)
	for col = 1, 20 do
		for row = 1, 10 do
			local rgb = const.color[p[player].board[col][row]]
			p[player].boardGroup[col][row]:setFillColor(rgb[1], rgb[2], rgb[3])
		end
	end
end

local function checkGhost(player)
	for i = 1, 4 do
		local x0 = p[player].pos.x + p[player].piece[2 * i - 1]
		local y0 = p[player].ghostY + p[player].piece[2 * i]
		if (y0 > 20 or p[player].board[y0][x0] < 8) then return false end
	end
	return true
end

local function paintGhost(player, flag)
	if (flag == true) then
		p[player].ghostY = p[player].pos.y + 1
		while (checkGhost(player) == true) do p[player].ghostY = p[player].ghostY + 1 end
		p[player].ghostY = p[player].ghostY - 1
	end
	local rgb = const.color[flag and p[player].nowPieceId or 8]
	for i = 1, 4 do
		if (p[player].pos.y + p[player].piece[2 * i] > 0) then
			p[player].boardGroup[p[player].pos.y + p[player].piece[2 * i]][p[player].pos.x + p[player].piece[2 * i - 1]]:setFillColor(rgb[1], rgb[2], rgb[3], flag and 0.2 or 1)
		end
	end
end

local function createPiece(player)
	for i = 0, 8 do p[player].piece[i] = const.pieces[p[player].nowPieceId][i] end
	p[player].pos.x = 5
	p[player].pos.y = 0
end

local function paintNowPiece(player, flag)
	local rgb = const.color[flag and p[player].nowPieceId or 8]
	for i = 1, 4 do
		if (p[player].pos.y + p[player].piece[2 * i] > 0) then
			p[player].boardGroup[p[player].pos.y + p[player].piece[2 * i]][p[player].pos.x + p[player].piece[2 * i - 1]]:setFillColor(rgb[1], rgb[2], rgb[3], 1)
		end
	end
end

local function paintNextPiece(player, flag)
	local rgb = const.color[flag and p[player].nextPieceId or 8]
	for i = 1, 4 do
		p[player].nextPieceGroup[3 + const.pieces[p[player].nextPieceId][2 * i]][2 + const.pieces[p[player].nextPieceId][2 * i - 1]]:setFillColor(rgb[1], rgb[2], rgb[3])
	end
end

local function paintStoredPiece(player, flag)
	local rgb = const.color[flag and p[player].storedPieceId or 8]
	for i = 1, 4 do
		p[player].storedPieceGroup[3 + const.pieces[p[player].storedPieceId][2 * i]][2 + const.pieces[p[player].storedPieceId][2 * i - 1]]:setFillColor(rgb[1], rgb[2], rgb[3])
	end
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
		if (y > 20 or x < 1 or x > 10 or p[player].board[y][x] < 8) then return false end
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
			if (event.keyName == p[player].hold and p[player].changePiece == false) then
				paintStoredPiece(player, false)
				paintNowPiece(player, false)
				paintGhost(player, false)
				p[player].nowPieceId, p[player].storedPieceId = p[player].storedPieceId, p[player].nowPieceId
				p[player].pos.x, p[player].pos.y = 5, 0
				p[player].changePiece = true
				for i = 0, 8 do p[player].piece[i] = const.pieces[p[player].nowPieceId][i] end
				paintGhost(player, true)
				paintNowPiece(player, true)
				paintStoredPiece(player, true)
			end
			if (event.keyName == p[player].hard) then
				paintNowPiece(player, false)
				paintGhost(player, false)
				p[player].pos.y = p[player].ghostY
				p[player].interval = 15
				paintGhost(player, true)
				paintNowPiece(player, true)
			end
			if (event.keyName == p[player].cw0 or event.keyName == p[player].cw) then
				paintNowPiece(player, false)
				paintGhost(player, false)
				p[player].spin = rotate(player, 1)
				paintGhost(player, true)
				paintNowPiece(player, true)
			end
			if (event.keyName == p[player].ccw) then
				paintNowPiece(player, false)
				paintGhost(player, false)
				p[player].spin = rotate(player, -1)
				paintGhost(player, true)
				paintNowPiece(player, true)
			end
			if (event.keyName == p[player].right or event.keyName == p[player].left or event.keyName == p[player].soft) then
				p[player].delay = 1
				keyboard[event.keyName] = true
			end
		elseif (event.keyName == p[player].right or event.keyName == p[player].left or event.keyName == p[player].soft) then
			keyboard[event.keyName] = false
		end
	end
end

local function onKeepPressEvent(player)

	p[player].delay = p[player].delay - 1

	if (p[player].delay == 0) then

		paintNowPiece(player, false)
		paintGhost(player, false)

		if keyboard[p[player].soft] then
			move(player, 0, 1)
			if (p[player].pos.y == p[player].ghostY) then p[player].interval = 15 end
		end

		if keyboard[p[player].right] then move(player, 1, 0) end
		if keyboard[p[player].left] then move(player, -1, 0) end

		paintGhost(player, true)
		paintNowPiece(player, true)

		p[player].delay = 5 - math.floor((p[player].level - 1) / 6)
	end
end

local function onFrameEvent(player)

	p[player].interval = p[player].interval - 1

	if (winner > 0) then
		-- show game over alert
	elseif (p[player].interval == 0) then
		paintNowPiece(player, false)
		if (move(player, 0, 1) == false) then
			paintGhost(player, false)
			setPiece(player)
			p[player].changePiece = false
			scanBoard(player)
			if (isGameOver(player) == true) then
				winner = 3 - player
				p[player].interval = -1
			else
				rearrangeBoard(player)
				paintBoard(player)
				getRandomPiece(player)
				createPiece(player)
				paintGhost(player, true)
			end
		end

		paintNowPiece(player, true)

		if (p[player].lines >= 5 * p[player].level) then
			p[player].level = p[player].level + 1
		end

		if (p[player].level > 30) then winner = player end

		if (p[player].pos.y == p[player].ghostY) then
			p[player].interval = 15
		else 
			p[player].interval = 31 - p[player].level
		end
	end
end

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

	local p1BoardArea = display.newRect(mainGroup, WIDTH / 2 - 12 * half, HEIGHT / 2, HEIGHT / 2, HEIGHT)
	local p1NextPieceArea = display.newRoundedRect(mainGroup, WIDTH / 4 - 11 * half, HEIGHT / 4, 10 * half, 10 * half, 10)
	local p1StoredPieceArea = display.newRoundedRect(mainGroup, WIDTH / 4 - 11 * half, 3 * HEIGHT / 4, 10 * half, 10 * half, 10)

	local p1String = display.newText({
		parent = mainGroup,
		text = "1P",
		x = WIDTH / 4 - 11 * half,
		y = HEIGHT / 2,
		font = native.systemFont,
		fontSize = 75,
		align = "center"
	})
	p1String:setFillColor(0, 0, 0)

	local p1NextPieceString = display.newText({
		parent = mainGroup,
		text = "NEXT",
		x = WIDTH / 4 - 11 * half,
		y = HEIGHT / 4 - 8 * half,
		font = native.systemFont,
		fontSize = 50,
		align = "center"
	})
	p1NextPieceString:setFillColor(0, 0, 0)

	local p1StoredPieceString = display.newText({
		parent = mainGroup,
		text = "HOLD",
		x = WIDTH / 4 - 11 * half,
		y = 3 * HEIGHT / 4 + 8 * half,
		font = native.systemFont,
		fontSize = 50,
		align = "center"
	})
	p1StoredPieceString:setFillColor(0, 0, 0)

	local p2BoardArea = display.newRect(mainGroup, WIDTH / 2 + 12 * half, HEIGHT / 2, HEIGHT / 2, HEIGHT)
	local p2NextPieceArea = display.newRoundedRect(mainGroup, 3 * WIDTH / 4 + 11 * half, HEIGHT / 4, 10 * half, 10 * half, 10)
	local p2StoredPieceArea = display.newRoundedRect(mainGroup, 3 * WIDTH / 4 + 11 * half, 3 * HEIGHT / 4, 10 * half, 10 * half, 10)
	
	local p2String = display.newText({
		parent = mainGroup,
		text = "2P",
		x = 3 * WIDTH / 4 + 11 * half,
		y = HEIGHT / 2,
		font = native.systemFont,
		fontSize = 75,
		align = "center"
	})
	p2String:setFillColor(0, 0, 0)
	
	local p2NextPieceString = display.newText({
		parent = mainGroup,
		text = "NEXT",
		x = 3 * WIDTH / 4 + 11 * half,
		y = HEIGHT / 4 - 8 * half,
		font = native.systemFont,
		fontSize = 50,
		align = "center"
	})
	p2NextPieceString:setFillColor(0, 0, 0)

	local p2StoredPieceString = display.newText({
		parent = mainGroup,
		text = "HOLD",
		x = 3 * WIDTH / 4 + 11 * half,
		y = 3 * HEIGHT / 4 + 8 * half,
		font = native.systemFont,
		fontSize = 50,
		align = "center"
	})
	p2StoredPieceString:setFillColor(0, 0, 0)

	local p1BoardX = WIDTH / 2 - 22 * half
	local p2BoardX = WIDTH / 2 + 2 * half
	local p1PieceX = WIDTH / 4 - 15 * half
	local p2PieceX = 3 * WIDTH / 4 + 7 * half
	local nextY = HEIGHT / 4 - 4 * half
	local storedY = 3 * HEIGHT / 4 - 4 * half

	p[1].boardGroup = display.newGroup()
	sceneGroup:insert(p[1].boardGroup)

	for col = 1, 20 do
		local line = display.newGroup()
		for row = 1, 10 do
			local grid = display.newRect(line, p1BoardX + (2 * row - 1) * half, (2 * col - 1) * half, 2 * half, 2 * half)
			grid:setStrokeColor(0.5, 0.5, 0.5, 0.8)
			grid.strokeWidth = half / 25
		end
		p[1].boardGroup:insert(line)
	end

	p[1].nextPieceGroup = display.newGroup()
	sceneGroup:insert(p[1].nextPieceGroup)

	for col = 1, 4 do
		local line = display.newGroup()
		for row = 1, 4 do
			local grid = display.newRect(line, p1PieceX + (2 * row - 1) * half, nextY + (2 * col - 1) * half, 2 * half, 2 * half)
			grid:setStrokeColor(0.5, 0.5, 0.5, 0.8)
			grid.strokeWidth = half / 25
		end
		p[1].nextPieceGroup:insert(line)
	end

	p[1].storedPieceGroup = display.newGroup()
	sceneGroup:insert(p[1].storedPieceGroup)

	for col = 1, 4 do
		local line = display.newGroup()
		for row = 1, 4 do
			local grid = display.newRect(line, p1PieceX + (2 * row - 1) * half, storedY + (2 * col - 1) * half, 2 * half, 2 * half)
			grid:setStrokeColor(0.5, 0.5, 0.5, 0.8)
			grid.strokeWidth = half / 25
		end
		p[1].storedPieceGroup:insert(line)
	end

	p[2].boardGroup = display.newGroup()
	sceneGroup:insert(p[2].boardGroup)

	for col = 1, 20 do
		local line = display.newGroup()
		for row = 1, 10 do
			local grid = display.newRect(line, p2BoardX + (2 * row - 1) * half, (2 * col - 1) * half, 2 * half, 2 * half)
			grid:setStrokeColor(0.5, 0.5, 0.5, 0.8)
			grid.strokeWidth = half / 25
		end
		p[2].boardGroup:insert(line)
	end

	p[2].nextPieceGroup = display.newGroup()
	sceneGroup:insert(p[2].nextPieceGroup)

	for col = 1, 4 do
		local line = display.newGroup()
		for row = 1, 4 do
			local grid = display.newRect(line, p2PieceX + (2 * row - 1) * half, nextY + (2 * col - 1) * half, 2 * half, 2 * half)
			grid:setStrokeColor(0.5, 0.5, 0.5, 0.8)
			grid.strokeWidth = half / 25
		end
		p[2].nextPieceGroup:insert(line)
	end

	p[2].storedPieceGroup = display.newGroup()
	sceneGroup:insert(p[2].storedPieceGroup)

	for col = 1, 4 do
		local line = display.newGroup()
		for row = 1, 4 do
			local grid = display.newRect(line, p2PieceX + (2 * row - 1) * half, storedY + (2 * col - 1) * half, 2 * half, 2 * half)
			grid:setStrokeColor(0.5, 0.5, 0.5, 0.8)
			grid.strokeWidth = half / 25
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

	local finalLevelArea = display.newRoundedRect(gameOverGroup, 3 * WIDTH / 8, HEIGHT / 2 - 5 * half, 16 * half, 4 * half, 10)
	finalLevelArea:setFillColor(251 / 255, 206 / 255, 177 / 255, 0.8)
	finalLevelArea.alpha = 0.8

	local finalLevelVarArea = display.newRoundedRect(gameOverGroup, 5 * WIDTH / 8, HEIGHT / 2 - 5 * half, 16 * half, 4 * half, 10)
	finalLevelVarArea:setFillColor(251 / 255, 206 / 255, 177 / 255, 0.8)
	finalLevelVarArea.alpha = 0.8

	local finalLinesArea = display.newRoundedRect(gameOverGroup, 3 * WIDTH / 8, HEIGHT / 2, 16 * half, 4 * half, 10)
	finalLinesArea:setFillColor(251 / 255, 206 / 255, 177 / 255, 0.8)
	finalLinesArea.alpha = 0.8

	local finalLinesVarArea = display.newRoundedRect(gameOverGroup, 5 * WIDTH / 8, HEIGHT / 2, 16 * half, 4 * half, 10)
	finalLinesVarArea:setFillColor(251 / 255, 206 / 255, 177 / 255, 0.8)
	finalLinesVarArea.alpha = 0.8

	local finalScoreArea = display.newRoundedRect(gameOverGroup, 3 * WIDTH / 8, HEIGHT / 2 + 5 * half, 16 * half, 4 * half, 10)
	finalScoreArea:setFillColor(251 / 255, 206 / 255, 177 / 255, 0.8)
	finalScoreArea.alpha = 0.8

	local finalScoreVarArea = display.newRoundedRect(gameOverGroup, 5 * WIDTH / 8, HEIGHT / 2 + 5 * half, 16 * half, 4 * half, 10)
	finalScoreVarArea:setFillColor(251 / 255, 206 / 255, 177 / 255, 0.8)
	finalScoreVarArea.alpha = 0.8

	replayButton = display.newRoundedRect(gameOverGroup, 3 * WIDTH / 8, HEIGHT / 2 + 3 * WIDTH / 16, 16 * half, 6 * half, 10)
	replayButton:setFillColor(203 / 255, 125 / 255, 96 / 255, 0.8)
	replayButton.alpha = 0.8

	backMainButton = display.newRoundedRect(gameOverGroup, 5 * WIDTH / 8, HEIGHT / 2 + 3 * WIDTH / 16, 16 * half, 6 * half, 10)
	backMainButton:setFillColor(203 / 255, 125 / 255, 96 / 255, 0.8)
	backMainButton.alpha = 0.8

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

	local finalLevelString = display.newText({
		parent = gameOverGroup,
		text = "LEVEL",
		x = 3 * WIDTH / 8,
		y = HEIGHT / 2 - 5 * half,
		font = native.systemFont,
		fontSize = 50,
		align = "center"
	})
	finalLevelString:setFillColor(0, 0, 0)

	finalLevelText = display.newText({
		parent = gameOverGroup,
		text = "Lorem Ipsum",
		x = 5 * WIDTH / 8,
		y = HEIGHT / 2 - 5 * half,
		font = native.systemFont,
		fontSize = 50,
		align = "right"
	})
	finalLevelText:setFillColor(0, 0, 0)

	local finalLinesString = display.newText({
		parent = gameOverGroup,
		text = "LINES",
		x = 3 * WIDTH / 8,
		y = HEIGHT / 2,
		font = native.systemFont,
		fontSize = 50,
		align = "center"
	})
	finalLinesString:setFillColor(0, 0, 0)

	finalLinesText = display.newText({
		parent = gameOverGroup,
		text = "Lorem Ipsum",
		x = 5 * WIDTH / 8,
		y = HEIGHT / 2,
		font = native.systemFont,
		fontSize = 50,
		align = "right"
	})
	finalLinesText:setFillColor(0, 0, 0)

	local finalScoreString = display.newText({
		parent = gameOverGroup,
		text = "SCORE",
		x = 3 * WIDTH / 8,
		y = HEIGHT / 2 + 5 * half,
		font = native.systemFont,
		fontSize = 50,
		align = "center"
	})
	finalScoreString:setFillColor(0, 0, 0)

	finalScoreText = display.newText({
		parent = gameOverGroup,
		text = "Lorem Ipsum",
		x = 5 * WIDTH / 8,
		y = HEIGHT / 2 + 5 * half,
		font = native.systemFont,
		fontSize = 50,
		align = "right"
	})
	finalScoreText:setFillColor(0, 0, 0)

	local replayText = display.newText({
		parent = gameOverGroup,
		text = "REPLAY",
		x = 3 * WIDTH / 8,
		y = HEIGHT / 2 + 3 * WIDTH / 16,
		font = native.systemFont,
		fontSize = 50,
		align = "center"
	})
	replayText:setFillColor(0, 0, 0)

	local backMainText = display.newText({
		parent = gameOverGroup,
		text = "MAIN",
		x = 5 * WIDTH / 8,
		y = HEIGHT / 2 + 3 * WIDTH / 16,
		font = native.systemFont,
		fontSize = 50,
		align = "center"
	})
	backMainText:setFillColor(0, 0, 0)

	for col = 1, 20 do
		p[1].board[col] = {}
		p[2].board[col] = {}
		for row = 1, 10 do
			p[1].board[col][row] = 8
			p[2].board[col][row] = 8
		end
	end
	getRandomPiece(1)
	getRandomPiece(2)
	paintStoredPiece(1, true)
	paintStoredPiece(2, true)

end


-- show()
function scene:show( event )

	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		-- Code here runs when the scene is still off screen (but is about to come on screen)

	elseif ( phase == "did" ) then
		-- Code here runs when the scene is entirely on screen

		Runtime:addEventListener("key", onCommonKeyEvent)
		for player = 1, 2 do
			Runtime:addEventListener("key", function(event) onKeyEvent(event, player) end)
			Runtime:addEventListener("enterFrame", function() onKeepPressEvent(player) end)
			Runtime:addEventListener("enterFrame", function() onFrameEvent(player) end)
		end

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
