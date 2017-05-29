local Object = require "lib.classic"
local anim8 = require "lib.anim8"

-- it's a sprite,
local Sprite = Object:extend()

function Sprite:new(image, x, y, offset_x, offset_y, flip_offset_x, flip_offset_y)
    self.image = love.graphics.newImage(image)
    -- disable aliasing
    self.image:setFilter("nearest", "nearest", 0)
    -- set the image to tile if drawn on a quad bigger than it actually is
    self.image:setWrap("repeat", "repeat")
    self.x = x or 0
    self.y = y or 0
    -- gotta use a quad for wrapping
    local width = self.image:getWidth()
    local height = self.image:getHeight()
    self.quad = love.graphics.newQuad(0, 0, width, height, width, height)
    -- scale: positive if facing right, negative if facing left
    self.scaleX = 1
    self.scaleY = 1
    -- offsets for drawing the sprite
    self.offsetX = offset_x or 0
    self.offsetY = offset_y or 0
    -- offset to apply when flipping the sprite
    self.flipOffsetX = flip_offset_x or (width - self.offsetX * 2)
    self.flipOffsetY = flip_offset_y or (height - self.offsetY * 2)
end

function Sprite:draw()
    love.graphics.draw(self.image, self.quad, self.x, self.y, 0,
                       self.scaleX, self.scaleY, self.offsetX, self.offsetY)
end

function Sprite:getWidth()
    return self.image:getWidth()
end

function Sprite:getHeight()
    return self.image:getHeight()
end

function Sprite:setPos(x, y)
    self.x = x
    self.y = y
end

function Sprite:getXPos(x, y)
    return self.x
end

function Sprite:getYPos(x, y)
    return self.y
end

function Sprite:move(dx, dy)
    self.x = self.x + dx
    self.y = self.y + dy
end

-- flip the image and apply the flip offset
function Sprite:flip(direction)
    if direction == "vertical" then
        -- negate scale so the sprite faces the right way
        self.scaleY = -self.scaleY
        if self:isMirrored("vertical") then
            self.offsetY = self.offsetY + self.flipOffsetY
        else
            self.offsetY = self.offsetY - self.flipOffsetY
        end
    else
        -- negate scale so the sprite faces the right way
        self.scaleX = -self.scaleX
        if self:isMirrored() then
            self.offsetX = self.offsetX + self.flipOffsetX
        else
            self.offsetX = self.offsetX - self.flipOffsetX
        end
    end
end

-- returns true if the sprite is currently flipped
function Sprite:isMirrored(direction)
    if direction == "vertical" then
        return self.scaleY < 0
    else
        return self.scaleX < 0
    end
end

-- an animated sprite
local AnimatedSprite = Sprite:extend()

function AnimatedSprite:new(frame_width, frame_height, ...)
    AnimatedSprite.super.new(self, ...)
    self.grid = anim8.newGrid(frame_width, frame_height, self:getWidth(), self:getHeight())
    self.animations = {}
    self.animation = nil
end

function AnimatedSprite:update(dt)
    self.animation:update(dt)
end

function AnimatedSprite:draw()
    self.animation:draw(self.image, self.x, self.y, 0,
                        self.scaleX, 1, self.offsetX, self.offsetY)
end

-- add an animation
function AnimatedSprite:addAnimation(name, x, y, ...)
    self.animations[name] = anim8.newAnimation(self.grid(x, y), ...)
    -- if this is the first animation, set it as the default
    if not self.animation then
        self.animation = self.animations[name]
    end
end

-- switch to the given animation
function AnimatedSprite:setAnimation(name)
    -- reset, replace, resume
    self.animation:pauseAtStart()
    self.animation = self.animations[name]
    self.animation:resume()
end

-- /!\ GOOD PROGRAMMER ALERT /!\
-- these functions reach right into anim8's guts,
-- don't expect them to work with newer versions
-- /!\ GOOD PROGRAMMER ALERT /!\

-- returns how long the current loop has been running
function AnimatedSprite:getTime()
    return self.animation.timer
end

-- skips the animation to the time given
function AnimatedSprite:setTime(time)
    -- figure out what frame we need
    local frame = nil
    for i, interval in ipairs(self.animation.intervals) do
        if not frame and (time - interval) < 0 then
            frame = i - 1
        end
    end
    -- set the frame and timer
    self.animation.position = frame
    self.animation.timer = time
end

return {
    Sprite = Sprite,
    AnimatedSprite = AnimatedSprite
}
