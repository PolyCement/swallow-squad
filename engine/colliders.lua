local Object = require "lib.classic"
local vector = require "lib.hump.vector"

-- a basic aabb collider
local Collider = Object:extend()

function Collider:new(parent, x, y, w, h)
    self.pos, self.width, self.height = vector(x, y), w, h
    self.solid = true
    -- callback function
    self.onCollision = function() end
    -- tag (so other colliders know what hit em)
    self.tag = ""
    -- the object this component belongs to
    self.parent = parent
    -- previous position, for collision resolution
    self.lastPos = vector(0, 0)
    -- register with collision handler
    collisionHandler:add(self)
end

-- delete yourself!
function Collider:remove()
    collisionHandler:remove(self)
end

function Collider:setCallback(func)
    self.onCollision = func
end

function Collider:onGround()
    return collisionHandler:onGround(self)
end

function Collider:getTag()
    return self.tag
end

function Collider:setTag(tag)
    self.tag = tag
end

function Collider:getParent()
    return self.parent
end

-- draw the collider's bounding box
function Collider:drawBoundingBox()
    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(255, 0, 0, 255)
    love.graphics.rectangle("line", self.pos.x, self.pos.y, self.width, self.height)
    love.graphics.setColor(r, g, b, a)
end

-- move by the requested amount
function Collider:move(delta)
    self.lastPos = self.pos
    self.pos = self.pos + delta
end

-- move in a specific axis
-- used by the collision handler to step movement in one axis at a time
function Collider:moveX(dx)
    self.lastPos.x = self.pos.x
    self.pos.x = self.pos.x + dx
end

function Collider:moveY(dy)
    self.lastPos.y = self.pos.y
    self.pos.y = self.pos.y + dy
end

function Collider:isSolid()
    return self.solid
end

function Collider:getCenter()
    return vector(self.pos.x + self.width/2, self.pos.y + self.height/2)
end

function Collider:__tostring()
    return "Collider"
end

-- a non-solid collider
-- does this really need a subclass? literally the only difference is solidity
local Trigger = Collider:extend()

function Trigger:new(...)
    Trigger.super.new(self, ...)
    self.solid = false
end

return {
    Collider = Collider,
    Trigger = Trigger
}
