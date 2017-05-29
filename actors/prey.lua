local Object = require "lib.classic"
local sprite = require "engine.sprite"
local colliders = require "engine.colliders"

-- messages yelled by prey
local messages = {}

-- messages for all prey
messages["all"] = {
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

-- species-specific dialogue
messages["dog"] = {
    "Awooooo!",
    "Boof!",
    "Bork!",
    "Arf!",
    "Yip! Yap!",
    "What a hog, to swallow a dog!",
    "Get me arf this roof!",
    "Quick! Wolf me down!"
}

messages["cat"] = {
    ":3c",
    "Get meow-t of here!",
    "Myelp!",
    "Mrrrrrrooow?!",
    "Ugh, watch the fur.",
    "I promise not to scratch...",
    "Fancy that, to swallow a cat!",
    "I taste good, trust me."
}

messages["taur"] = {
    "Ready for me?",
    "Big enough to hold me?",
    "Got enough room in there?",
    "Be warned: I'm big!",
    "Huh, usually I'm the pred.",
    "Open wide!",
    "Hurry and vore this taur!"
}

-- speech bubble used by prey
local SpeechBubble = Object:extend()

local font = love.graphics.newFont("assets/fonts/StarPerv.ttf", 7)
font:setFilter("nearest", "nearest", 0)

-- x and y denote lower left position of speech bubble (ie. source of the bubble's tail)
function SpeechBubble:new(x, y)
    -- sprite for speech bubble tail
    self.tailSprite = sprite.Sprite("assets/images/shout_tail.png")
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
local Prey = colliders.Collider:extend()

function Prey:new(species, x, y)
    -- please select your vehicle
    self.species = species
    -- define the sprite, then use its dimensions to determine our vertices
    self.sprite = sprite.Sprite(self.species:getImagePath(), x, y, 1, 1)
    local x2 = x + self.sprite:getWidth() - 2
    local y2 = y + self.sprite:getHeight() - 2
    Prey.super.new(self, false, x, y, x2, y, x2, y2, x, y2)
    -- stuff for shouting at the player
    self.speechBubble = SpeechBubble(x2, y)
    self.shouting = false
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
            self.speechBubble:setMessage(self.species:getMessage())
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
    if obj == player and not obj:isFull() then
        collisionHandler:remove(self)
        prey[self] = nil
    end
end

function Prey:getWeight()
    return self.species:getWeight()
end

-- species (type objects so i don't have to subclass every single prey type)
local Species = Object:extend()

function Species:new(imagepath, messagetype, weight)
    self.imagepath = imagepath
    self.weight = weight or 1
    -- build message list
    self.messages = {unpack(messages["all"])}
    for idx = 1, #messages[messagetype] do
        self.messages[#self.messages+1] = messages[messagetype][idx]
    end
end

function Species:getImagePath()
    return self.imagepath
end

function Species:getMessage()
    return self.messages[math.random(#self.messages)]
end

function Species:getWeight()
    return self.weight
end

function Species:newPrey(x, y)
    return Prey(self, x, y)
end

local species = {}

species["wolf"] = Species("assets/images/prey_wolf.png", "dog")
species["cat"] = Species("assets/images/prey_wolf.png", "cat")
species["taur"] = Species("assets/images/taur_fox.png", "taur", 3)

-- returns a random non-taur species
local function get_random_species()
    local all_species = {}
    for k, v in pairs(species) do
        if k ~= "taur" then
            all_species[#all_species+1] = v
        end
    end
    return all_species[math.random(#all_species)]
end

return {
    Prey = Prey,
    species = species,
    get_random_species = get_random_species
}
