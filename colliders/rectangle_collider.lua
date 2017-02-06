-- rectangular collider
RectangleCollider = Collider:extend()

function RectangleCollider:new(x, y, width, height, solid)
    local x2 = x + width
    local y2 = y + height
    RectangleCollider.super.new(self, solid, vector(x, y), vector(x2, y), vector(x2, y2), vector(x, y2))
end

function RectangleCollider:__tostring()
    return "RectangleCollider"
end
