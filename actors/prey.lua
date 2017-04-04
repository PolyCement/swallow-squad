Object = require "lib.classic"
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

-- speech bubble used by prey
SpeechBubble = Object:extend()

local font = love.graphics.newFont("assets/fonts/StarPerv.ttf", 7)
font:setFilter("nearest", "nearest", 0)

-- x and y denote lower left position of speech bubble (ie. source of the bubble's tail)
function SpeechBubble:new(x, y)
    -- sprite for speech bubble tail
    self.tailSprite = Sprite("assets/images/shout_tail.png")
    self.tailSprite:setPos(x, y - self.tailSprite:getHeight())
    -- x positions don't change
    self.black_x = x
    self.white_x = self.black_x + 1
    self.text_x = self.white_x + 2
    -- set a default message to initialise dimensions and y positions
    self:setMessage(":o3")
end

-- set message and update speech bubble size to fit
function SpeechBubble:setMessage(message)
    self.message = message
    -- set width, height and y position of speech bubble based on message
    local message_w = font:getWidth(self.message)
    local message_h = font:getHeight(self.message)
    self.white_w, self.white_h = message_w + 3, message_h + 3
    self.black_w, self.black_h = self.white_w + 2, self.white_h + 2
    self.text_y = self.tailSprite:getYPos() - (message_h + 1)
    self.white_y = self.text_y - 2
    self.black_y = self.white_y - 1
end

function SpeechBubble:draw()
    -- draw black rectangle (outline)
    love.graphics.setColor(0, 0, 0, 255)
    love.graphics.rectangle("fill", self.black_x, self.black_y, self.black_w, self.black_h)
    -- draw white rectangle
    love.graphics.setColor(255, 255, 255, 255)
    love.graphics.rectangle("fill", self.white_x, self.white_y, self.white_w, self.white_h)
    -- draw "tail"
    self.tailSprite:draw()
    -- draw text
    love.graphics.setColor(0, 0, 0, 255)
    love.graphics.setFont(font)
    love.graphics.print(self.message, self.text_x, self.text_y)
    love.graphics.setColor(255, 255, 255, 255)
end

-- tasty!
Prey = Collider:extend()

function Prey:new(image, x, y)
    -- define the sprite first, then use its dimensions to determine our vertices
    self.sprite = Sprite(image, x, y, 1, 1)
    local x2 = x + self.sprite:getWidth() - 2
    local y2 = y + self.sprite:getHeight() - 2
    Prey.super.new(self, false, x, y, x2, y, x2, y2, x, y2)
    -- stuff for shouting at the player
    self.speechBubble = SpeechBubble(x2, y)
    self.shouting = false
    -- how heavy are we
    self.weight = 1
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
        if not self.shouting then
            self.shouting = true
            self.speechBubble:setMessage(messages[math.random(#messages)])
        end
    else
        self.shouting = false
    end
end

function Prey:draw()
    if self.shouting then
        self.speechBubble:draw()
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
