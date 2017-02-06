-- tasty!
Prey = RectangleCollider:extend()

function Prey:new(image, x, y)
    -- will this work if dimensions aren't given? lets find out lol
    self.sprite = Sprite(image, x, y)
    Prey.super.new(self, x, y, self.sprite:getWidth(), self.sprite:getHeight())
    self.solid = false
    -- override width and height with the actual size our sprite ends up
    -- create and register our collider
    collisionHandler:add(self)
end

function Prey:draw()
    Prey.super.draw(self)
    self.sprite:draw()
end

function Prey:onCollision()
    print("wow!")
    collisionHandler:remove(self)
    prey[self] = nil
end
