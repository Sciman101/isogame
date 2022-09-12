local helpers = require 'helpers'

local isogrid = {}
isogrid.__index = isogrid

local VERTEX_FORMAT = {
	{'VertexPosition','float',3},
	{'VertexTexCoord','float',2}
}
local Tiles = {
	wall={
		shape='block',
		uv={0,0,0.5,0.5}
	},
	rgb={
		shape='block',
		uv={0,0.5,0.5,1}
	},
	floor={
		shape='floor',
		uv={0.5,0.5,1,0.75}
	},
	atlas=love.graphics.newImage('assets/DiagonalTile.png')
}
-- TEMP code
Tiles.atlas:setFilter('nearest','nearest')

function isogrid.new(width,height,tilesize)
	local grid = setmetatable({},isogrid)

	-- Grid dimensions. X goes down and to the right, y goes down and to the left
	grid.width = width
	grid.height = height
	grid.count = width*height

	grid.x = 0
	grid.y = 0

	-- Half the vertical size of one tile
	grid.size = tilesize

	-- Set grid data
	for i=1,grid.count do
		grid[i] = love.math.random() < 0.1 and Tiles.rgb or Tiles.floor
	end

	return grid
end

-- Coordinate conversion
function isogrid:tileToWorld(x,y)
	-- This returns the CENTER of the tile
	return 2*self.size*(x-y)+self.x,(x+y)*self.size+self.y
end

function isogrid:worldToTile(x,y)
	x = x - self.x
	y = y - self.y

	local tx = x/(self.size*4) + y/(self.size*2) + 0.5
    return math.floor(tx),math.floor(tx-x/self.size*2)
end

function isogrid:pointInMapBounds(x,y)
	return x >= 0 and y >= 0 and x < self.width and y < self.height
end

function isogrid:getTile(x,y)
	if not self:pointInMapBounds(x,y) then return nil end
	return self[x+y*self.width]
end

function isogrid:getBoundingSize()
	return (self.width*2+self.height*2)*self.size,(self.width+self.height)*self.size
end

-- Add a quad-shaped tile to the vertex list
-- x/y is the top left corner, w/h is the dimensions
function addQuad(vertices,tile,x,y,w,h,z)
	local u,v,uu,vv = helpers.unwrap(tile.uv)

	local i = #vertices
	vertices[i + 1] = {x,y,z,		u,v}
	vertices[i + 2] = {x+w,y,z,		uu,v}
	vertices[i + 3] = {x+w,y+h,z,	uu,vv}

	vertices[i + 4] = {x,y,z,		u,v}
	vertices[i + 5] = {x+w,y+h,z,	uu,vv}
	vertices[i + 6] = {x,y+h,z,		u,vv}
end

function isogrid:buildMesh()

	local vertices = {}

	local boundW, boundH = self:getBoundingSize()

	local x,y = 0,0
	for i=1,self.count do

		local tile = self[i]
		local wx, wy = self:tileToWorld(x,y)

		if tile then
			if tile.shape == 'block' then
				addQuad(vertices,tile,wx-self.size*2,wy-self.size*3,self.size*4,self.size*4,wy*0.005)
			elseif tile.shape == 'floor' then
				addQuad(vertices,tile,wx-self.size*2,wy-self.size,self.size*4,self.size*2,-5)
			end
		end

		x = x + 1
		if x >= self.width then
			x = 0
			y = y + 1
		end
	end
	-- Build mesh
	self.mesh = love.graphics.newMesh(VERTEX_FORMAT,vertices,'triangles','static')
	self.mesh:setTexture(Tiles.atlas)
end

function isogrid:draw()
	if self.mesh then
		love.graphics.draw(self.mesh,self.x,self.y)
	else
		self:buildMesh()
	end
end


return isogrid