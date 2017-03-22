require "engine.sprite"
anim8 = require "lib.anim8"

-- an animated sprite
AnimatedSprite = Sprite:extend()

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
