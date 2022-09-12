Object = require 'lib/classic'

local CORNERS = {-1,0,0,1,1,0,0,-1}

Entity = Object:extend()

function Entity:new(x,y,s)
	self.x = x or 0
	self.y = y or 0
	self.s = s or 8 -- Size of entity (half height of diamond hitbox)
end

function Entity:move(dx,dy)
	dx = dx or 0
	dy = dy or 0

	self.x = self.x + dx
	self.y = self.y + dy
end

function Entity:getOverlappingTile(isogrid)
	local s2 = self.s*2
	-- TODO make this work for entities larger than an isomap tile
	for i=1,8,2 do
		local tx,ty = isogrid:worldToTile(self.x+s2*CORNERS[i],self.y+self.s*CORNERS[i+1])
		local t = isogrid:getTile(tx,ty)
		if t then return t,tx,ty end
	end
	return nil
end

-- Try to move by dx,dy. If a collision occurs, return the tile we collided with, otherwise return nil
function Entity:testMove(dx,dy,isogrid)
	self:move(dx,dy)
	local t,tx,ty = self:getOverlappingTile(isogrid)
	-- Go back
	self:move(-dx,-dy)

	return t,tx,ty
end

-- Draw the entity
function Entity:draw()
	-- Debug draw
	love.graphics.setColor(1,1,1)
	local x,y,s,s2 = math.floor(self.x),math.floor(self.y),self.s,self.s*2
	love.graphics.polygon('line',x-s2,y, x,y-s, x+s2,y, x,y+s)
	love.graphics.line(x,y,x,y-s)
end

return Entity