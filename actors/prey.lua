require "colliders.collider"
require "engine.sprite"

-- messages yelled by prey
local messages = {
    "Finally!",
    "Is this safe?",
    "Cool if I strip first?",
    "<3",
    "What big teeth you have!",
    "Help!",
    "Help me!",
    "Nice!",
    "Cool!",
    "Please...",
    "My hero!",
    "Room for one more?",
    "Room for another?",
    "OwO",
    "Eat me!",
    "Let me know how I taste!",
    "I've dreamed about this!",
    "Just like my dreams!",
    "Don't digest me...!",
    "Just... don't digest me.",
    "Save me!",
    "Savour me...",
    "Devour me!",
    "But how do I get out?",
    "Can I... y'know... in there?",
    "Uh? How do we get out?",
    "Just gobble me up!",
    "Swallow me already!"
}

-- tasty!
Prey = Collider:extend()

local font = love.graphics.newFont("assets/fonts/StarPerv.ttf", 7)
font:setFilter("nearest", "nearest", 0)

function Prey:new(image, x, y)
    -- define the sprite first, then use its dimensions to determine our vertices
    self.sprite = Sprite(image, x, y, 1, 1)
    local x2 = x + self.sprite:getWidth() - 2
    local y2 = y + self.sprite:getHeight() - 2
    Prey.super.new(self, false, x, y, x2, y, x2, y2, x, y2)
    -- how heavy are we
    self.weight = 1
    -- what are we yelling?
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
        -- maybe these should be calculated earlier and stored
        -- text position
        local text_x, text_y = self.vertices[2].x, self.vertices[2].y - 16
        -- white rectangle position and dimensions
        local white_x, white_y = text_x - 2, text_y - 2
        local white_w, white_h = font:getWidth(self.message) + 3, font:getHeight(self.message) + 3
        -- black rectangle (outline) position and dimensions
        local black_x, black_y = white_x - 1, white_y - 1
        local black_w, black_h = white_w + 2, white_h + 2
        -- draw black rectangle (outline)
        love.graphics.setColor(0, 0, 0, 255)
        love.graphics.rectangle("fill", black_x, black_y, black_w, black_h)
        -- draw white rectangle
        love.graphics.setColor(255, 255, 255, 255)
        love.graphics.rectangle("fill", white_x, white_y, white_w, white_h)
        -- draw text
        love.graphics.setColor(0, 0, 0, 255)
        love.graphics.setFont(font)
        love.graphics.print(self.message, text_x, text_y)
        love.graphics.setColor(255, 255, 255, 255)
    end
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
