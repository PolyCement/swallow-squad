-- representation of an image drawn in the game
-- basically just a wrapper around love.graphics.Image
Sprite = Object:extend()

function Sprite:new(image, x, y, width, height, offset_x, offset_y)
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
    -- scaling factor for sprite
    -- positive if facing right, negative if facing left
    self.scaleX = 1
    -- offsets for drawing the sprite
    self.offsetX = offset_x
    self.offsetY = offset_y
end

function Sprite:draw()
    love.graphics.draw(self.image, self.quad, self.x, self.y, 0,
                       self.scaleX, 1, self.offsetX, self.offsetY)
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

-- flip the image about x + width/2
-- ok but what if instead of passing width here i gave the sprite a pivot axis in its constructor
-- passing width seems really odd? shouldn't the sprite know the axis it should mirror over???
function Sprite:flip(width)
    -- first negate scale so the sprite faces the right way
    self.scaleX = -self.scaleX
    if self:isMirrored() then
        self.offsetX = self.offsetX + width
    else
        self.offsetX = self.offsetX - width
    end
end

-- returns true if the sprite is currently flipped
function Sprite:isMirrored()
    return self.scaleX < 0
end
