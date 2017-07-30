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

-- move by the requested amount, correct our position if we hit something
--function Collider:move(delta)
--    movement_helper(self, delta)
--    local correction_delta = collisionHandler:checkCollision(self)
--    movement_helper(self, correction_delta)
--end

function Collider:isSolid()
    return self.solid
end

function Collider:__tostring()
    return "Collider"
end

-- a one-way platform
local Platform = Collider:extend()

-- a on the left, b on the right
function Platform:new(a_x, a_y, b_x, b_y)
    Platform.super.new(self, a_x, a_y, b_x, b_y) 
end

-- platforms are only solid if the given collider was above them on the previous cycle
function Platform:isSolid(collider)
    -- if the collider was above the bounding box of the platform, stay solid (allows hanging on edges)
    if collider.lastPos.y <= math.min(self.vertices[1].y, self.vertices[2].y) then
        return true
    end
    -- if the determinant of ba and "ca" is negative, we're above the platform
    local ca = collider.lastPos - self.vertices[1]
    local ba = self.edges[1].direction
    local determinant = ba.x * ca.y - ba.y * ca.x
    return determinant < 0
end

-- a non-solid collider
local Trigger = Collider:extend()

function Trigger:new(...)
    Trigger.super.new(self, ...)
    self.solid = false
end

return {
    Collider = Collider,
    Platform = Platform,
    Trigger = Trigger
}
