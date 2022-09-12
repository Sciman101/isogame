package.path = ";src/?.lua;" .. package.path
love.graphics.setDefaultFilter("nearest", "nearest")

-- NOTE FOR Z AXIS
-- POSITIVE Z IS 'TOWARDS THE CAMERA'

local flux = require 'lib/flux'

local Isogrid = require 'isogrid'
local Entity = require 'entity/entity'

local mainCanvas, depthCanvas
local discardAlphaDepthShader = love.graphics.newShader('src/shaders/clipalpha_depth.glsl')
local rToRGB = love.graphics.newShader('src/shaders/r_to_rgb.glsl')

local grid
local player = nil
local entities = {}

local cx, cy = 320,180

function love.load()

	-- Set up canvases for rendering
	mainCanvas = love.graphics.newCanvas(640,360,{type = "2d", format = "normal", readable = true, mipmaps = "auto"})
	depthCanvas = love.graphics.newCanvas(640,360,{type = "2d", format = "depth32f", readable = true, mipmaps = "none"})
	love.graphics.setDepthMode('lequal',true)

	grid = Isogrid.new(16,16,8)

	player = Entity(0,0,6)
	entities[1] = player

	-- Build da mesh
	grid:buildMesh()
end

function getAxis(neg,pos)
	local x = 0
	if love.keyboard.isDown(neg) then x = x - 1 end
	if love.keyboard.isDown(pos) then x = x + 1 end
	return x
end

function sign(x)
	return x > 0 and 1 or (x < 0 and -1 or 0)
end

function love.update(dt)
    flux.update(dt)

	-- camera control
	-- mostly for debugging
	--if love.keyboard.isDown('right') then cx = cx - dt * 100 end
	--if love.keyboard.isDown('left') then cx = cx + dt * 100 end
	--if love.keyboard.isDown('up') then cy = cy + dt * 100 end
	--if love.keyboard.isDown('down') then cy = cy - dt * 100 end

	local dx,dy = getAxis('left','right'),getAxis('up','down')
	if dx ~= 0 or dy ~= 0 then
		if math.abs(dx) == math.abs(dy) then
			dy = dy * 0.5
		end
		local dist = math.sqrt(dx*dx+dy*dy)
		dx = dx / dist
		dy = dy / dist
	end

	if player:testMove(dx*dt,0,grid) then
		local xx = sign(dx)
		while not player:testMove(xx,0,grid) do player.x = player.x + xx end
		dx = 0
	end

	if player:testMove(0,dy*dt,grid) then
		local yy = sign(dy)
		while not player:testMove(0,yy,grid) do player.y = player.y + yy end
		dy = 0
	end

	player:move(dx*dt,dy*dt)

	cx = 320-player.x
	cy = 180-player.y
end

function love.draw()
	love.graphics.setCanvas({mainCanvas,depthstencil=depthCanvas})
	love.graphics.clear(0,0,0,1,0,10000)

	love.graphics.setShader(discardAlphaDepthShader)
	discardAlphaDepthShader:send('z_offset',0)

	-- Do normal drawing here
	love.graphics.push()
	love.graphics.translate(math.floor(cx),math.floor(cy))

	-- Draw tilemap
	discardAlphaDepthShader:send('z_offset',(grid.y-cy)*0.005)
	grid:draw()

	for i=1,#entities do
		local entity = entities[i]
		discardAlphaDepthShader:send('z_offset',(entity.y-cy)*0.005)
		entity:draw()
	end

	love.graphics.setShader()
	local mx, my = love.mouse.getPosition()
	local tx,ty = grid:tileToWorld(grid:worldToTile(mx/2-cx,my/2-cy))
	love.graphics.polygon('line',tx-16,ty, tx,ty-8, tx+16,ty, tx,ty+8)
	love.graphics.circle('line',mx/2-cx,my/2-cy,8)
	-- End normal drawing
	love.graphics.pop()

	love.graphics.setCanvas()
	love.graphics.setShader()
	love.graphics.draw(mainCanvas,0,0,0,2,2)
end