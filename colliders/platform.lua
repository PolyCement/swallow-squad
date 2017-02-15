-- a one-way platform
Platform = Collider:extend()

-- assumes b is to the right of a
function Platform:new(a, b)
    Platform.super.new(self, true, a, b) 
end

-- platforms are only solid if the player was above them on the previous cycle
function Platform:isSolid()
    -- if we're moving upwards the platform shouldn't be solid
    if player.velocity.y < 0 then
        return false
    end
    -- if the player was above the bounding box of the platform, stay solid (allows hanging on edges)
    if player.prevBottomPos.y <= math.min(self.vertices[1].y, self.vertices[2].y) then
        return true
    end
    -- if the determinant of ba and "ca" is negative, we're above the platform
    local ca = player.prevBottomPos - self.vertices[1]
    local ba = self.edges[1].direction
    local determinant = ba.x * ca.y - ba.y * ca.x
    return determinant < 0
end
