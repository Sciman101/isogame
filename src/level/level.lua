local Level = Object:extend()


function Level:new(w,h)

    -- Dimensions of the tilemap
    self.width = 0
    self.height = 0
    self.tilemap = {}

    self.chunks = {}
    self.entities = {}
end

function Level:draw()
end

return Level