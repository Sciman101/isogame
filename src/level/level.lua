local helpers = require 'helpers'

local Level = Object:extend()

-- Length of a chunk on one side, in tiles
Level.CHUNK_SIZE = 32
Level.VERTEX_FORMAT = {
	{'VertexPosition','float',3},
	{'VertexTexCoord','float',2}
}

local Tiles = {
	wall={
		shape='block',
		solid=true,
		uv={0,0,0.5,0.5}
	},
	rgb={
		shape='block',
		solid=true,
		uv={0,0.5,0.5,1}
	},
	floor={
		shape='floor',
		solid=false,
		uv={0.5,0.5,1,0.75}
	},
	atlas=love.graphics.newImage('assets/DiagonalTile.png')
}

function Level:new(width,height,tilesize)
	-- Grid dimensions. X goes down and to the right, y goes down and to the left
	self.tiles = {}

	self.width = width
	self.height = height
	self.count = width*height

	-- Half the vertical size of one tile
	self.size = tilesize

	-- Determine chunk dimensions
    self.chunks = {}

	self.chunkWidth = math.ceil(self.width/Level.CHUNK_SIZE)
	self.chunkHeight = math.ceil(self.height/Level.CHUNK_SIZE)
	self.chunkCount = self.chunkWidth*self.chunkHeight

	self.chunkRenderWidth = (Level.CHUNK_SIZE*4)*self.size
	self.chunkRenderHeight = (Level.CHUNK_SIZE*2)*self.size

	-- Set grid data
	for i=1,self.count do
		self.tiles[i] = love.math.random() > 0.01 and Tiles.floor or Tiles.rgb
	end
	self.tiles[1] = Tiles.floor

	-- Init chunk data
	for cx=0,self.chunkWidth-1 do
		for cy=0,self.chunkHeight-1 do
			local chunkIndex = cx+cy*self.chunkWidth + 1
			self.chunks[chunkIndex] = {
				mesh = nil,
				-- chunk coordinates
				cx = cx,
				cy = cy,
				-- World coordinates, used for rendering. Unlike tiles, this is centered on the top left corner
				x = self.chunkRenderWidth*0.5*(cx-cy),
				y = (cx+cy)*self.chunkRenderHeight*0.5,
				dirty = true
			}
		end
	end

	print('Level with size (' .. self.width .. ',' .. self.height .. '), chunk size ' .. Level.CHUNK_SIZE .. ' and chunk dimensions (' .. self.chunkWidth .. ',' .. self.chunkHeight .. ')')
end

-- Coordinate conversion
function Level:tileToWorld(x,y)
	-- This returns the CENTER of the tile
	return 2*self.size*(x-y),(x+y)*self.size
end

function Level:worldToTile(x,y)
	local tx = x/(self.size*4) + y/(self.size*2) + 0.5
    return math.floor(tx),math.floor(tx-(x/(self.size*2)))
end

function Level:chunkCoordFromTileCoord(tx,ty)
	return math.floor(tx/Level.CHUNK_SIZE),math.floor(ty/Level.CHUNK_SIZE)
end

function Level:pointInMapBounds(x,y)
	return x >= 0 and y >= 0 and x < self.width and y < self.height
end

function Level:getTile(x,y)
	if not self:pointInMapBounds(x,y) then return nil end
	return self.tiles[x+y*self.width+1]
end

function Level:getBoundingSize()
	return (self.width*2+self.height*2)*self.size,(self.width+self.height)*self.size
end

function Level:draw()
	for i=1,self.chunkCount do
		local chunk = self.chunks[i]
		if chunk.mesh then
			love.graphics.draw(chunk.mesh,chunk.x,chunk.y)
		end
	end
end

-- Generate EVERY mesh for the level
function Level:generateMeshes()
	for cx=0,self.chunkWidth-1 do
		for cy=0,self.chunkHeight-1 do
			local chunkIndex = cx+cy*self.chunkWidth + 1
			local chunk = self.chunks[chunkIndex]
			if chunk.dirty then
				self:buildMesh(chunk)
				chunk.dirty = false
			end
		end
	end
end

-- Generate an individual mesh for a single chunk
function Level:buildMesh(chunk)

	print('Building chunk at ('..chunk.cx..','..chunk.cy..')')

	local vertices = {}

	for x=0,Level.CHUNK_SIZE-1 do
		for y=0,Level.CHUNK_SIZE-1 do

			-- Cooridnates of the tile relative to the entire level
			local absX = x + chunk.cx * Level.CHUNK_SIZE
			local absY = y + chunk.cy * Level.CHUNK_SIZE

			-- Coordinates of the tile in render space relative to the chunk
			local cx,cy = self:tileToWorld(x,y)

			-- The tile we need to mesh
			local tile = self.tiles[absX + absY * self.width + 1]

			if tile then
				if tile.shape == 'block' then
					addQuad(vertices,tile,cx-self.size*2,cy-self.size*3,self.size*4,self.size*4,cy*0.005)
				elseif tile.shape == 'floor' then
					addQuad(vertices,tile,cx-self.size*2,cy-self.size,self.size*4,self.size*2,cy*0.005-5)
				end
			end

		end
	end
	-- Build mesh
	if #vertices > 0 then
		print('Chunk generated w/ ' .. #vertices .. ' vertices')
		chunk.mesh = love.graphics.newMesh(Level.VERTEX_FORMAT,vertices,'triangles','static')
		chunk.mesh:setTexture(Tiles.atlas)
	else
		print('Empty chunk @ ' .. chunk.cx .. ', ' .. chunk.cy)
		chunk.mesh = nil
	end
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

return Level