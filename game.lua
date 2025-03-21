
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

local board = {}
local isFull = {}

local color =
{
	{1, 0, 0},
	{0, 1, 0},
	{0, 0, 1},
	{1, 1, 0},
	{1, 0, 1},
	{0, 1, 1},
	{0, 0, 0},
	{1, 1, 1},
}

local pieces =
{
	{ -- I
		left = -1,
		right = 2,
		other = {{-1, 0}, {0, 0}, {1, 0}, {2, 0}},
	},
	{ -- O
		left = -1,
		right = 0,
		other = {{-1, -1}, {-1, 0}, {0, -1}, {0, 0}},
	},
	{ -- T
		left = -1,
		right = 1,
		other = {{-1, 0}, {0, 0}, {0, -1}, {1, 0}},
	},
	{ -- J
		left = -1,
		right = 1,
		other = {{-1, -1}, {-1, 0}, {0, 0}, {1, 0}},
	},
	{ -- L
		left = -1,
		right = 1,
		other = {{-1, 0}, {0, 0}, {1, 0}, {1, -1}},
	},
	{ -- S
		left = -1,
		right = 1,
		other = {{-1, 0}, {0, 0}, {0, -1}, {1, -1}},
	},
	{ -- Z
		left = -1,
		right = 1,
		other = {{-1, -1}, {0, 0}, {0, -1}, {1, 0}},
	},
	{ -- dummy
		left = 0,
		right = 0,
		other = {{0, 0}, {0, 0}, {0, 0}, {0, 0}},
	}
}

local pos = {x = 0, y = 20}
local piece =
{
	left = 0,
	right = 0,
	other = {{0, 0}, {0, 0}, {0, 0}, {0, 0}},
}

local nextBlock
local storedBlock

local limit = 30
local remain = 1
local id = 8
local score

local function scanBoard()
	for col = 1, 20 do
		isFull[col] = true
		for row = 1, 10 do
			if (board[col][row] == 8) then
				isFull[col] = false
				break
			end
		end
	end
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
			mainGroup[col][row]:setFillColor(rgb[1], rgb[2], rgb[3])
		end
	end
end

local function setPiece(n)
	for i = 1, 4 do
		board[pos.y + piece.other[i][2]][pos.x + piece.other[i][1]] = n
	end
end

local function predictBottom(id)
	local x0, y0 = pos.x, pos.y
	while (y0 <= 20) do
		local impossible = false
		y0 = y0 + 1
		for i = 1, 4 do
			local y = y0 + piece.other[i][2]
			if (y > 20 or board[y][x0 + piece.other[i][1]] < 8) then
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
		if (event.keyName == "esc") then

		elseif (event.keyName == "space") then
			pos.y = predictBottom(id)
		elseif (event.keyName == "up") then
			if (pos.y < predictBottom(id)) then
				local left, right = 0, 0
				for i = 1, 4 do
					piece.other[i][1], piece.other[i][2] = -piece.other[i][2], piece.other[i][1]
					left = math.min(left, piece.other[i][1])
					right = math.max(right, piece.other[i][1])
				end
				piece.left = left
				piece.right = right
			end
		elseif (event.keyName == "down") then
			if (pos.y < predictBottom(id)) then
				pos.y = pos.y + 1
			end
		elseif (event.keyName == "left") then
			if (pos.x + piece.left > 1) then
				pos.x = pos.x - 1
			end
		elseif (event.keyName == "right") then
			if (pos.x + piece.right < 10) then
				pos.x = pos.x + 1
			end
		end
		setPiece(id)
		paintBlocks()
	end
end

local function onFrameEvent()

	remain = remain - 1

	if (remain == 0) then
		setPiece(8)
		if (pos.y == predictBottom(id)) then
			setPiece(id)
			scanBoard()
			rearrangeBoard()
			id = math.random(7)
			for k, v in pairs(pieces[id]) do piece[k] = v end
			pos.x, pos.y = 5, 2
			setPiece(id)
		else
			pos.y = pos.y + 1
			setPiece(id)
		end
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

	mainGroup = display.newGroup()
	sceneGroup:insert(mainGroup)

	uiGroup = display.newGroup()
	sceneGroup:insert(uiGroup)

	background = display.newRect(backGroup, display.contentCenterX, display.contentCenterY, display.contentWidth, display.contentHeight)
	background:setFillColor(251 / 255, 206 / 255, 177 / 255, 0.8)

	for col = 1, 20 do isFull[col] = false end

	local start = display.contentWidth / 2 - display.contentHeight / 4
	local half = display.contentHeight / 40

	for col = 1, 20 do
		local line = display.newGroup()
		local arr = {}
		for row = 1, 10 do
			display.newRect(line, start + (2 * row - 1) * half, (2 * col - 1) * half, 2 * half, 2 * half)
			arr[row] = 8
		end
		mainGroup:insert(line)
		board[col] = arr
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
