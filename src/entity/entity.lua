local CORNERS = {2,0, 0,1, -2,0, 0,-1}

Entity = Object:extend()

function Entity:new(x,y,s)
	self.x = x or 0
	self.y = y or 0
	self.s = s or 8 -- Size of entity (half height of diamond hitbox)

	self.level = nil -- Our associated level

	self.collisions = {
		right = false,
		left = false,
		top = false,
		bottom = false,

		tl=false,
		tr=false,
		bl=false,
		br=false
	}
end

-- Utilities --

function Entity:move(dx,dy)
	dx = dx or 0
	dy = dy or 0

	self.x = self.x + dx
	self.y = self.y + dy
end

function Entity:moveTo(x,y)
	self.x = x
	self.y = y
end

function Entity:resetCollisions()
	self.collisions.left = false
	self.collisions.right = false
	self.collisions.top = false
	self.collisions.bottom = false

	self.collisions.tl = false
	self.collisions.tr = false
	self.collisions.bl = false
	self.collisions.br = false
end

function Entity:getBoundingRect()
	local s2 = self.s*2
	return self.x-s2,self.y-self.s,s2*2,s2
end

-- Tilemap collision --

function Entity:getOverlappingTile(isogrid,solidOnly)
	-- TODO make this work for entities larger than an isomap tile
	for i=1,8,2 do
		local tx,ty = isogrid:worldToTile(self.x+self.s*CORNERS[i],self.y+self.s*CORNERS[i+1])
		local t = isogrid:getTile(tx,ty)
		if t and (t.solid == solidOnly) then return t,tx,ty end
	end
	return nil
end

function Entity:testMove(dx,dy,isogrid)
	self:move(dx,dy)
	local t,tx,ty = self:getOverlappingTile(isogrid,true)
	-- Go back
	self:move(-dx,-dy)

	local doCollide = t and t.solid

	return doCollide,t,tx,ty
end

-- Entity collision --

function Entity:pointInSelf(x,y)
	x = x - self.x
	y = y - self.y
	local a = 0.5 * math.abs(x) - self.s
	return y > a and y < -a
end

function Entity:overlapsEntity(other)
	if not other:is(Entity) then return false end
	if other.s > self.s then
		return other:overlapsEntity(self)
	end
	for i=1,8,2 do
		local overlap = self:pointInSelf(other.x+other.s*CORNERS[i],other.y+other.s*CORNERS[i+1])
		if overlap then return overlap end
	end
	return false
end

-- Rendering --

function Entity:draw()
	-- Debug draw
	love.graphics.setColor(1,1,1)
	local x,y,s,s2 = math.floor(self.x),math.floor(self.y),self.s,self.s*2
	love.graphics.polygon('line',x-s2,y, x,y-s, x+s2,y, x,y+s)
	love.graphics.line(x,y,x,y-s)
end

return Entity