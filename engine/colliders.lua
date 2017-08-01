local Object = require "lib.classic"
local vector = require "lib.hump.vector"

-- a basic aabb collider, to be used as a component
local Collider = Object:extend()

-- its an aabb again.....
function Collider:new(x, y, w, h)
    self.pos, self.width, self.height = vector(x, y), w, h
    -- solidity
    self.solid = true
    -- callback function
    self.onCollision = function() end
    -- tag (so other colliders know what hit em)
    self.tag = ""
    -- parent, for when a collider's parents need to know about each other in order to react properly
    -- (only useful for a handful of colliders, so it's optional)
    self.parent = nil
    -- Previous position (needed for collision resolution)
    self.lastPos = vector(0, 0)
end

function Collider:setCallback(func)
    self.onCollision = func
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

function Collider:setParent(parent)
    self.parent = parent
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
