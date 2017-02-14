-- a one-way plaform
Platform = Collider:extend()

function Platform:new(a, b)
    local c = b + vector(0, 5)
    local d = a + vector(0, 5)
    Platform.super.new(self, true, a, b, c, d) 
end

-- platforms are only solid when the player was above them on the previous cycle
function Platform:isSolid()
    return player.prevBottomHeight <= self.vertices[1].y
end
