Object = require "lib.classic"

-- it's a sprite,
Sprite = Object:extend()

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
