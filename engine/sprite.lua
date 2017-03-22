Object = require "lib.classic"

-- it's a sprite,
Sprite = Object:extend()

function Sprite:new(image, x, y, offset_x, offset_y, flip_offset)
    self.image = love.graphics.newImage(image)
    -- set the image to tile if drawn on a quad bigger than it actually is
    self.image:setWrap("repeat", "repeat")
    self.x = x
    self.y = y
    -- gotta use a quad for wrapping
    local width = self.image:getWidth()
    local height = self.image:getHeight()
    self.quad = love.graphics.newQuad(0, 0, width, height, width, height)
    -- scale: positive if facing right, negative if facing left
    self.scaleX = 1
    -- offsets for drawing the sprite
    self.offsetX = offset_x or 0
    self.offsetY = offset_y or 0
    -- offset to apply when flipping the sprite
    self.flipOffset = flip_offset or (width - self.offsetX * 2)
end

function Sprite:draw()
    love.graphics.draw(self.image, self.quad, self.x, self.y, 0,
                       self.scaleX, 1, self.offsetX, self.offsetY)
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

function Sprite:move(dx, dy)
    self.x = self.x + dx
    self.y = self.y + dy
end

-- flip the image and apply the flip offset
function Sprite:flip()
    -- negate scale so the sprite faces the right way
    self.scaleX = -self.scaleX
    if self:isMirrored() then
        self.offsetX = self.offsetX + self.flipOffset
    else
        self.offsetX = self.offsetX - self.flipOffset
    end
end

-- returns true if the sprite is currently flipped
function Sprite:isMirrored()
    return self.scaleX < 0
end
