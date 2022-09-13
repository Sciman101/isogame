package.path = ";src/?.lua;" .. package.path
love.graphics.setDefaultFilter("nearest", "nearest")
Object = require 'lib/classic'

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
local entity2 = nil
local entities = {}

local cx, cy = 320,180

function love.load()

	-- Set up canvases for rendering
	mainCanvas = love.graphics.newCanvas(640,360,{type = "2d", format = "normal", readable = true, mipmaps = "auto"})
	depthCanvas = love.graphics.newCanvas(640,360,{type = "2d", format = "depth32f", readable = true, mipmaps = "none"})
	love.graphics.setDepthMode('lequal',true)

	local SIZE = 500
	grid = Isogrid.new(SIZE,SIZE,8)

	player = Entity(0,0,6)
	entity2 = Entity(0,100,8)
	entities[1] = player
	entities[2] = entity2

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
	return x and (x > 0 and 1 or (x < 0 and -1 or 0)) or 0
end

function love.update(dt)
    flux.update(dt)

	-- camera control
	-- mostly for debugging
	--if love.keyboard.isDown('right') then cx = cx - dt * 100 end
	--if love.keyboard.isDown('left') then cx = cx + dt * 100 end
	--if love.keyboard.isDown('up') then cy = cy + dt * 100 end
	--if love.keyboard.isDown('down') then cy = cy - dt * 100 end

	local dx,dy = getAxis('a','d'),getAxis('w','s')
	if dx ~= 0 or dy ~= 0 then
		if math.abs(dx) == math.abs(dy) then
			dy = dy * 0.5
		end
		local dist = math.sqrt(dx*dx+dy*dy)
		dx = (dx / dist) * 100
		dy = (dy / dist) * 100
	end

	player:resetCollisions()

	local slideX, slideY = 0

	local collide,t,tx,ty = player:testMove(dx*dt,0,grid)
	if collide then
		local xx = sign(dx)
		slideX = dx
		while not player:testMove(xx,0,grid) do
			player.x = player.x + xx
		end
		dx = 0

		player.collisions.left = xx < 0
		player.collisions.right = xx > 0

		local _, twy = grid:tileToWorld(tx,ty)
		if twy > player.y then
			player.collisions.br = xx > 0
			player.collisions.bl = xx < 0
		else
			player.collisions.tr = xx > 0
			player.collisions.tl = xx < 0
		end

		-- Slide
		if slideX ~= 0 then
			slideY = math.abs(slideX * 0.5)
			if player.collisions.br or player.collisions.bl then slideY = -slideY end
			
			if player:testMove(slideX*dt,slideY*dt,grid) then
				local yy = sign(slideY)
				while not player:testMove(xx*2,yy,grid) do
					player.x = player.x + xx*2
					player.y = player.y + yy
				end
				slideY = 0
				slideX = 0
			end
			player:move(slideX*dt,slideY*dt)
		end
	end

	collide,t,tx,ty = player:testMove(0,dy*dt,grid)
	if collide then
		local yy = sign(dy)
		slideY = dy
		while not player:testMove(0,yy,grid) do
			player.y = player.y + yy
		end
		dy = 0

		player.collisions.top = yy < 0
		player.collisions.bottom = yy > 0

		local twx = grid:tileToWorld(tx,ty)
		if twx > player.x then
			player.collisions.tr = yy < 0
			player.collisions.br = yy > 0
		else
			player.collisions.tl = yy < 0
			player.collisions.bl = yy > 0
		end

		-- Slide
		if slideY ~= 0 then
			slideX = math.abs(slideY)
			slideY = 0.5 * slideY
			if player.collisions.br or player.collisions.tr then slideX = -slideX end
			
			if player:testMove(slideX*dt,slideY*dt,grid) then
				local xx = sign(slideX)
				while not player:testMove(xx*2,yy,grid) do
					player.x = player.x + xx*2
					player.y = player.y + yy
				end
				slideY = 0
				slideX = 0
			end
			player:move(slideX*dt,slideY*dt)
		end
	end

	player:move(dx*dt,dy*dt)

	cx = 320-player.x
	cy = 180-player.y

	if player:overlapsEntity(entity2) then
		player.x = player.x - 1
	end
end

function love.draw()
	local draw_start = love.timer.getTime()

	love.graphics.setCanvas({mainCanvas,depthstencil=depthCanvas})
	love.graphics.clear(0,0,0,1,0,10000)
	love.graphics.setColor(1,1,1)

	love.graphics.setShader(discardAlphaDepthShader)
	discardAlphaDepthShader:send('z_offset',0)

	-- Do normal drawing here
	love.graphics.push()
	love.graphics.translate(math.floor(cx),math.floor(cy))

	-- Draw tilemap
	discardAlphaDepthShader:send('z_offset',(grid.y-cy)*0.005)
	grid:draw()

	local mx, my = love.mouse.getPosition()
	mx = mx/2-cx
	my = my/2-cy

	for i=1,#entities do
		local entity = entities[i]
		discardAlphaDepthShader:send('z_offset',(entity.y-cy)*0.005)
		entity:draw()
	end

	love.graphics.setShader()
	-- End normal drawing
	love.graphics.pop()

	love.graphics.setCanvas()
	love.graphics.setShader()
	love.graphics.draw(mainCanvas,0,0,0,2,2)

	local draw_end = love.timer.getTime()
	love.graphics.print('Frame draw time: ' .. (draw_end-draw_start),8,8)
end