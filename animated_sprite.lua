AnimatedSprite = Sprite:extend()

function AnimatedSprite:new(image, x, y, width, height, offset_x, offset_y)
    AnimatedSprite.super.new(self, image, x, y, width, height, offset_x, offset_y)
    local grid = anim8.newGrid(128, 128, self.width, self.height)
    self.animation = anim8.newAnimation(grid('1-4', 1), 0.2)
end

function AnimatedSprite:update(dt)
    self.animation:update(dt)
end

function AnimatedSprite:draw()
    self.animation:draw(self.image, self.x, self.y, 0,
                        self.scaleX, 1, self.offsetX, self.offsetY)
end

function AnimatedSprite:stop()
    self.animation:pauseAtStart()
end

function AnimatedSprite:pause()
    self.animation:pause()
end

function AnimatedSprite:resume()
    self.animation:resume()
end
