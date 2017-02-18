-- representation of an image drawn in the game
-- basically just a wrapper around love.graphics.Image
Sprite = Object:extend()

function Sprite:new(image, x, y, width, height, offset_x, offset_y, flip_offset)
    self.image = love.graphics.newImage(image)
    -- set the image to tile if drawn on a quad bigger than it actually is
    self.image:setWrap("repeat", "repeat")
    self.x = x
    self.y = y
    -- if no dimensions are specified just assume they match the sprite
    self.width = width or self.image:getWidth()
    self.height = height or self.image:getHeight()
    -- not 100% on what this does yet but we'll figure it out
    -- it's mandatory for using wrapping tho
    self.quad = love.graphics.newQuad(0, 0, self.width, self.height,
                                      self.image:getWidth(), self.image:getHeight())
    -- scale: positive if facing right, negative if facing left
    self.scaleX = 1
    -- offsets for drawing the sprite
    self.offsetX = offset_x or 0
    self.offsetY = offset_y or 0
    -- offset to apply when flipping the sprite
    self.flipOffset = flip_offset or self.width
end

function Sprite:draw()
    love.graphics.draw(self.image, self.quad, self.x, self.y, 0,
                       self.scaleX, 1, self.offsetX, self.offsetY)
end

-- AnimatedSprite overrides this, its useless here tho
function Sprite:update(dt)
end

function Sprite:getWidth()
    return self.width 
end

function Sprite:getHeight()
    return self.height
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

-- more stub functions so i can use sprite in player.lua without it crashing
-- todo: clean this mess up
function Sprite:stop()
end

function Sprite:pause()
end

function Sprite:resume()
end
