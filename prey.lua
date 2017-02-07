-- tasty!
Prey = RectangleCollider:extend()

function Prey:new(image, x, y)
    -- will this work if dimensions aren't given? lets find out lol
    self.sprite = Sprite(image, x, y)
    Prey.super.new(self, x, y, self.sprite:getWidth(), self.sprite:getHeight())
    self.solid = false
    -- register with collision handler
    -- tried to move this to the base collider class but it blew up
    -- cos it was adding each temporary collider to the handler
    -- while checking collisions
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
