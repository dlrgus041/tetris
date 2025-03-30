
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

local p =
{
	{ -- P1
		boardGroup,
		nextPieceGroup,
		storedPieceGroup,
		ghostY = 20,
		pos = {x = 5, y = 20},
		piece = { [0] = 0, 0,0, 0,0, 0,0, 0,0 },
		board = {[-1] = {8, 8, 8, 8, 8, 8, 8, 8}, [0] = {8, 8, 8, 8, 8, 8, 8, 8}},
		nowPieceId = 8,
		nextPieceId = 8,
		storedPieceId = 1,
		changePiece = false,
		isFalling = false,
		score = 0,
		lines = 0,
		level = 1,
		pauseAt = -1
	},
	{ -- P2
		boardGroup,
		nextPieceGroup,
		storedPieceGroup,
		ghostY = 20,
		pos = {x = 5, y = 20},
		piece = { [0] = 0, 0,0, 0,0, 0,0, 0,0 },
		board = {[-1] = {8, 8, 8, 8, 8, 8, 8, 8}, [0] = {8, 8, 8, 8, 8, 8, 8, 8}},
		nowPieceId = 8,
		nextPieceId = 8,
		storedPieceId = 1,
		changePiece = false,
		isFalling = false,
		score = 0,
		lines = 0,
		level = 1,
		pauseAt = -1
	}
}

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
	local rgb = const.color[clear and p[player].nowPieceId or 8]
	for i = 1, 4 do
		if (p[player].pos.y + p[player].piece[2 * i] > 0) then
			p[player].boardGroup[p[player].pos.y + p[player].piece[2 * i]][p[player].pos.x + p[player].piece[2 * i - 1]]:setFillColor(rgb[1], rgb[2], rgb[3], flag and 0.2 or 1)
		end
	end
end

local function paintNowPiece(player, clear)
	local rgb = const.color[clear and p[player].nowPieceId or 8]
	for i = 1, 4 do
		if (p[player].pos.y + p[player].piece[2 * i] > 0) then
			p[player].boardGroup[p[player].pos.y + p[player].piece[2 * i]][p[player].pos.x + p[player].piece[2 * i - 1]]:setFillColor(rgb[1], rgb[2], rgb[3], 1)
		end
	end
end

local function paintNextPiece(player, clear)
	local rgb = const.color[clear and p[player].nextPieceId or 8]
	for i = 1, 4 do
		p[player].nextPieceGroup[3 + p[player].pieces[p[player].nextPieceId][2 * i]][1 + p[player].pieces[p[player].nextPieceId][2 * i - 1]]:setFillColor(rgb[1], rgb[2], rgb[3])
	end
end

local function paintStoredPiece(player, clear)
	local rgb = const.color[clear and p[player].storedPieceId or 8]
	for i = 1, 4 do
		p[player].storedPieceGroup[3 + p[player].pieces[p[player].storedPieceId][2 * i]][1 + p[player].pieces[p[player].storedPieceId][2 * i - 1]]:setFillColor(rgb[1], rgb[2], rgb[3])
	end
end

local function getRandomPiece(player)
	paintNextPiece(player, true)
	if (#p[player].bag == 0) then
		for i = 1, 7 do
			p[player].bag[i] = i
			p[player].box[i] = math.random(49)
		end
		table.sort(p[player].bag, function(a, b) return p[player].box[a] > p[player].box[b] end)
	end
	p[player].nowPieceId = p[player].nextPieceId
	p[player].nextPieceId = table.remove(p[player].bag)
	paintNextPiece(player)
end

local function move(player, dx, dy, arr)
	local temp = {}
	for i = 0, 8 do temp[i] = arr and arr[i] or p[player].piece[i] end
	for i = 1, 4 do
		local x = p[player].pos.x + dx + temp[2 * i - 1]
		local y = p[player].pos.y + dy + temp[2 * i]
		if (y > 20 or x < 1 or x > 10 or p[player].board[y][x] < 8) then return false end
	end
	for i = 0, 8 do piece[i] = temp[i] end
	p[player].pos.x = p[player].pos.x + dx
	p[player].pos.y = p[player].pos.y + dy
	return true
end

local function rotate(player, clockwise)
	local temp = {[0] = p[player].piece[0]}
	for i = 1, 4 do
		if (clockwise == true) then
			temp[2 * i - 1] = p[player].piece[2 * i]
			temp[2 * i] = -p[player].piece[2 * i - 1]
		else
			temp[2 * i - 1] = -p[player].piece[2 * i]
			temp[2 * i] = p[player].piece[2 * i - 1]
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
