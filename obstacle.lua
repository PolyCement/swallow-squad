-- this should be used to define bits of scenery that we can collide with
-- YES THAT INCLUDES THE GROUND
Obstacle = RectangleCollider:extend()

function Obstacle:new(image, x, y, width, height)
    Obstacle.super.new(self, x, y, width, height)
    self.sprite = Sprite(image, self.x, self.y, self.width, self.height)
    -- register with the collision handler
    -- maybe the base class should do this? but i dont want player registered just yet
    collisionHandler:add(self)
end

function Obstacle:draw()
    Obstacle.super.draw(self)
    self.sprite:draw()
end

function Obstacle:__tostring()
    return "Obstacle"
end
