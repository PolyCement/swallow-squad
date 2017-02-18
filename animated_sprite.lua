-- really awful don't look
-- todo: figure out what to do about this mess
anim8 = require "lib.anim8"

AnimatedSprite = Sprite:extend()

function AnimatedSprite:new(image, x, y, width, height, offset_x, offset_y, flip_offset)
    AnimatedSprite.super.new(self, image, x, y, width, height, offset_x, offset_y, flip_offset)
    self.grid = anim8.newGrid(128, 139, self.width, self.height)
    self.animation = anim8.newAnimation(self.grid(9, 1), 0.075)
    self.stopped = true
end

function AnimatedSprite:update(dt)
    self.animation:update(dt)
end

function AnimatedSprite:draw()
    self.animation:draw(self.image, self.x, self.y, 0,
                        self.scaleX, 1, self.offsetX, self.offsetY)
end

function AnimatedSprite:stop()
    self.animation = anim8.newAnimation(self.grid(9, 1), 0.075)
    self.stopped = true
end

function AnimatedSprite:pause()
    self.animation:pause()
end

function AnimatedSprite:resume()
    self.animation = anim8.newAnimation(self.grid("1-8", 1), 0.075)
    self.stopped = false
end
