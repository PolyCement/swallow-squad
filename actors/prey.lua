-- messages yelled by prey
local messages = {
    "Finally!",
    "Is this safe?",
    "Thanks!",
    "Thank you!",
    "Thanks...",
    "Cool if I strip first?",
    "<3",
    "What big teeth you have!",
    "Again?",
    "Help!",
    "Help me!",
    "Nice!",
    "Cool!",
    "Please...",
    "My hero!",
    "Room for one more?",
    "OwO"
}

-- tasty!
Prey = RectangleCollider:extend()

local font = love.graphics.newFont(12)

function Prey:new(image, x, y)
    -- define the sprite first so we can use its dimensions to set our own
    self.sprite = Sprite(image, x, y, 1, 1)
    Prey.super.new(self, x, y, self.sprite:getWidth()-2, self.sprite:getHeight()-2)
    self.solid = false
    -- how heavy are we
    self.weight = 1
    -- are we yelling?
    self.message = nil
    -- are we looking left?
    self.facingLeft = true
    -- register with collision handler
    collisionHandler:add(self)
end

function Prey:update()
    local pos = self:getCenter()
    local player_pos = player:getCenter()
    -- turn to face the player
    if player_pos.x - pos.x < 0 then
        if not self.facingLeft then 
            self.sprite:flip()
            self.facingLeft = true
        end
    else
        if self.facingLeft then
            self.sprite:flip()
            self.facingLeft = false
        end
    end
    -- yell when the player gets close
    if pos:dist(player_pos) < 256 then
        if not self.message then
            self.message = messages[math.random(#messages)]
        end
    else
        self.message = nil
    end
end

function Prey:draw()
    if self.message then
        local shout_pos = self.vertices[2] + vector(0, -16)
        love.graphics.rectangle("fill", shout_pos.x, shout_pos.y,
                                font:getWidth(self.message), font:getHeight(self.message))
        love.graphics.setColor(0, 0, 0, 255)
        love.graphics.setFont(font)
        love.graphics.print(self.message, shout_pos.x, shout_pos.y)
        love.graphics.setColor(255, 255, 255, 255)
    end
    Prey.super.draw(self)
    self.sprite:draw()
end

-- remove when eaten
function Prey:onCollision(obj)
    if obj:is(Player) and not obj:isFull() then
        collisionHandler:remove(self)
        prey[self] = nil
    end
end

function Prey:getWeight()
    return self.weight
end

-- tasty but filling
Taur = Prey:extend()

function Taur:new(...)
    Taur.super.new(self, ...)
    self.weight = 3
end

function Taur:onCollision(obj)
    -- put some code here to tell the player they vored that taur
    Taur.super.onCollision(self, obj)
end
