-- tasty!
Prey = RectangleCollider:extend()

function Prey:new(image, x, y)
    -- will this work if dimensions aren't given? lets find out lol
    self.sprite = Sprite(image, x, y)
    Prey.super.new(self, x, y, self.sprite:getWidth(), self.sprite:getHeight())
    self.solid = false
    -- taur should set this to 3
    self.weight = 1
    -- are we yelling?
    self.isYelling = false
    -- register with collision handler
    collisionHandler:add(self)
end

function Prey:update()
    -- yell when the player gets close
    if self:getCenter():dist(player:getCenter()) < 256 then
        self.isYelling = true
    else
        self.isYelling = false
    end
end

function Prey:draw()
    if self.isYelling then
        local shout_pos = self.vertices[1] + vector(16, -16)
        love.graphics.setColor(0, 0, 0, 255)
        -- todo: different messages
        love.graphics.print("wow!", shout_pos.x, shout_pos.y)
        love.graphics.setColor(255, 255, 255, 255)
    end
    Prey.super.draw(self)
    self.sprite:draw()
end

-- remove when hit
function Prey:onCollision()
    collisionHandler:remove(self)
    prey[self] = nil
end
