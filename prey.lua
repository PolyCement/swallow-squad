-- tasty!
Prey = RectangleCollider:extend()

function Prey:new(image, x, y)
    -- will this work if dimensions aren't given? lets find out lol
    self.sprite = Sprite(image, x, y)
    Prey.super.new(self, x, y, self.sprite:getWidth(), self.sprite:getHeight())
    self.solid = false
    -- taur should set this to 3
    self.weight = 1
    -- register with collision handler
    collisionHandler:add(self)
end

function Prey:draw()
    Prey.super.draw(self)
    self.sprite:draw()
end

-- remove when hit
function Prey:onCollision()
    print("wow!")
    collisionHandler:remove(self)
    prey[self] = nil
end
