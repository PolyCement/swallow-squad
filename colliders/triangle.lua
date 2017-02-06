-- use this for sloped surfaces
-- should extend collider eventually
-- or just roll full polygonal collision support into collider whatever!!!!!!!!!
Triangle = Object:extend()

function Triangle:new(a, b, c)
    self.a = a
    self.b = b
    self.c = c
    self.x = math.min(a.x, b.x, c.x)
    self.y = math.min(a.y, b.y, c.y)
    self.width = math.max(a.x, b.x, c.x) - self.x
    self.height = math.max(a.y, b.y, c.y) - self.y
    -- figure out which 2 points define the hypotenuse
    -- i feel like there's a better way to do this that i haven't figured out on account of being an idiot
    local hyp_a, hyp_b
    if a.x ~= b.x and a.y ~= b.y then
        hyp_a, hyp_b = a, b
    elseif a.x ~= c.x and a.y ~= c.y then
        hyp_a, hyp_b = a, c
    else
        hyp_a, hyp_b = b, c
    end
    -- precompute normal of hypotenuse - the engine doesn't support rotation so this won't change
    local hypotenuse = vector(hyp_a.x - hyp_b.x, hyp_a.y - hyp_b.y)
    self.normal = hypotenuse:perpendicular():normalized()
    collisionHandler:add(self)
end

function Triangle:draw()
    if showColliders then
        local r, g, b, a = love.graphics.getColor()
        love.graphics.setColor(255, 0, 0, 255)
        love.graphics.polygon("line", self.a.x, self.a.y, self.b.x, self.b.y, self.c.x, self.c.y)
        love.graphics.setColor(r, g, b, a)
    end
end

function Triangle:getVertices()
    return {self.a, self.b, self.c}
end

-- really should merge this with the collider
function Triangle:isSolid()
    return true
end

function Triangle:onCollision() end

function Triangle:__tostring()
    return "Triangle"
end
