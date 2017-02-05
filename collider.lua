-- should an object collide with other objects? then it should extend this!
Collider = Object:extend()

function Collider:new(x, y, width, height, solid)
    self.x = x
    self.y = y
    self.width = width
    self.height = height
    -- the default should be true but obv "false or true" is true so i got this workaround
    if solid == nil then
        self.solid = true
    else
        self.solid = solid
    end
end

-- sets the callback function to the function given
function Collider:setCallback(callback_function)
    self.onCollision = callback_function
end

function Collider:draw()
    if showColliders then
        local r, g, b, a = love.graphics.getColor()
        love.graphics.setColor(255, 0, 0, 255)
        love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
        love.graphics.setColor(r, g, b, a)
    end
end

-- attempt to move by the requested amount, go where we can
function Collider:move(dx, dy)
    self.x, self.y = collisionHandler:checkCollision(self, dx, dy)
end

-- subclasses should override this
function Collider:onCollision() end

function Collider:isSolid()
    return self.solid
end

function Collider:__tostring()
    return "Collider"
end
