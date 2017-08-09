local Object = require "lib.classic"
local vector = require "lib.hump.vector"
local survivors = require "actors.prey"
local sprite = require "engine.sprite"
local colliders = require "engine.colliders"

-- pixels per meter
-- use this to specify things in meters rather than pixels
local METER = 16

-- constants for player behaviour
local MAX_CAPACITY = 12

-- speed constants
local MAX_SPEED = 20 * METER
local MIN_SPEED = MAX_SPEED * .5
local SPEED_PENALTY = (MAX_SPEED - MIN_SPEED) / MAX_CAPACITY

-- acceleration constants
local MAX_ACCELERATION = 32 * METER
local MIN_ACCELERATION = MAX_ACCELERATION * .5
local ACC_PENALTY = (MAX_ACCELERATION - MIN_ACCELERATION) / MAX_CAPACITY

-- jump constants
local MAX_JUMP_SPEED = 12 * METER
local MIN_JUMP_SPEED = MAX_JUMP_SPEED * .75
local JUMP_SPEED_PENALTY = (MAX_JUMP_SPEED - MIN_JUMP_SPEED) / MAX_CAPACITY
local MAX_TIME_JUMPING = .5
local MAX_JUMPS = 3

-- if the player's speed drops below this it's set to 0
local JIGGLE_PREVENTION = 5

-- template for state modelling
local PlayerState = Object:extend()

function PlayerState:new(player)
    -- track the player object so we can swap its state
    self.player = player
end

function PlayerState:enter()
end

function PlayerState:update(dt)
    -- gravity applies in all states
    -- uhh fuck u past me it should only apply if we're not grounded
    if not self.player.grounded then
        self.player.velocity.y = self.player.velocity.y + gravity * dt
    end
    self.player.collider:move(self.player.velocity * dt)
end

function PlayerState:keyPressed(key)
end

-- a nil obj indicates a world collision
-- im planning on forcing colliders to carry a reference to their parent
-- so i guess obj should probably be the collider's parent rather than the collider
-- that's a fix for later tho
function PlayerState:onCollision(colliding_side, obj)
    if obj ~= nil and obj:getTag() == "prey" then
        self.player:eat(obj:getParent())
    end
    if obj == nil or obj:isSolid() then
        if colliding_side == side.bottom or colliding_side == side.top then
            self.player.velocity.y = 0
            if colliding_side == side.bottom then
                self.player.grounded = true
            end
        elseif colliding_side == side.left or colliding_side == side.right then
            self.player.velocity.x = 0
        end
    end
end

function PlayerState:__tostring()
    return "PlayerState"
end

-- states
local StandingState = PlayerState:extend()

function StandingState:enter()
    self.player.jumpsLeft = MAX_JUMPS
    self.player:setAnimation("stand")
end

function StandingState:update(dt)
    -- state transitions
    if self.player.velocity.y > 0 then
        self.player:setState(self.player.falling)
        self.player.state:update(dt)
        return
    elseif love.keyboard.isDown("left") or love.keyboard.isDown("right") then
        self.player:setState(self.player.running)
        self.player.state:update(dt)
        return
    end
    -- decelerate
    if self.player.velocity.x > JIGGLE_PREVENTION then
        self.player:accelerate(-self.player.acceleration*dt)
    elseif self.player.velocity.x < -JIGGLE_PREVENTION then
        self.player:accelerate(self.player.acceleration*dt)
    else
        -- no jigglin
        self.player.velocity.x = 0
    end
    StandingState.super.update(self, dt)
    self.player.sprite:update(dt)
end

function StandingState:keyPressed(key)
    if key == "space" then
        self.player:setState(self.player.jumping)
    end
end

local RunningState = PlayerState:extend()

function RunningState:enter()
    self.player.jumpsLeft = MAX_JUMPS
    self.player:setAnimation("run")
end

function RunningState:update(dt)
    if self.player.velocity.y > 0 then
        self.player:setState(self.player.falling)
        self.player.state:update(dt)
        return
    elseif love.keyboard.isDown("left") then
        self.player:accelerate(-self.player.acceleration*dt)
        if not self.player.sprite:isMirrored() then
            self.player.sprite:flip()
        end
    elseif love.keyboard.isDown("right") then
        self.player:accelerate(self.player.acceleration*dt)
        if self.player.sprite:isMirrored() then
            self.player.sprite:flip()
        end
    else
        self.player:setState(self.player.standing)
        self.player.state:update(dt)
        return
    end
    RunningState.super.update(self, dt)
    self.player.sprite:update(dt * math.abs(self.player.velocity.x) / MAX_SPEED)
end

function RunningState:keyPressed(key)
    if key == "space" then
        self.player:setState(self.player.jumping)
    end
end

local JumpingState = PlayerState:extend()

function JumpingState:new(player)
    JumpingState.super.new(self, player)
    self.jumpSpeed = MAX_JUMP_SPEED
    self.timeJumping = 0
    self.jumpEnded = false
end

function JumpingState:enter()
    self.player.jumpsLeft = self.player.jumpsLeft - 1
    self.timeJumping = 0
    self.jumpEnded = false
    self.player.grounded = false
    -- initialise y velocity so air jumps don't immediately switch to falling
    self.player.velocity.y = -self.jumpSpeed
    self.player:setAnimation("jump")
end

function JumpingState:update(dt)
    if self.player.velocity.y > 0 then
        self.player:setState(self.player.falling)
        self.player.state:update(dt)
        return
    elseif love.keyboard.isDown("left") then
        self.player:accelerate(-self.player.acceleration*.5*dt)
    elseif love.keyboard.isDown("right") then
        self.player:accelerate(self.player.acceleration*.5*dt)
    end
    -- bounce bounce
    if love.keyboard.isDown("space") and not self.jumpEnded then
        if self.player.jumpsLeft >= 0 and self.timeJumping < MAX_TIME_JUMPING then
            self.timeJumping = self.timeJumping + dt
            self.player.velocity.y = -self.jumpSpeed
        end
    else
        -- this stops the player tapping space to gain extra height off the last jump
        self.jumpEnded = true
    end
    JumpingState.super.update(self, dt)
    self.player.sprite:update(dt)
end

function JumpingState:keyPressed(key)
    if key == "space" then
        if self.player.jumpsLeft > 0 then
            self.player:setState(self.player.jumping)
        end
    end
end

function JumpingState:onCollision(colliding_side, obj)
    JumpingState.super.onCollision(self, colliding_side, obj)
    if obj == nil or obj:isSolid() then
        if colliding_side == side.bottom then
            self.player:setState(self.player.standing)
        end
    end
end

local FallingState = PlayerState:extend()

function FallingState:enter()
    self.player:setAnimation("fall")
end

function FallingState:update(dt)
    -- while airbourne, allow the player to influence their speed a little
    if love.keyboard.isDown("left") then
        self.player:accelerate(-self.player.acceleration*.5*dt)
    elseif love.keyboard.isDown("right") then
        self.player:accelerate(self.player.acceleration*.5*dt)
    end
    FallingState.super.update(self, dt)
    self.player.sprite:update(dt)
end

function FallingState:keyPressed(key)
    if key == "space" then
        if self.player.jumpsLeft > 0 then
            self.player:setState(self.player.jumping)
        end
    end
end

function FallingState:onCollision(colliding_side, obj)
    FallingState.super.onCollision(self, colliding_side, obj)
    if obj == nil or obj:isSolid() then
        if colliding_side == side.bottom then
            self.player:setState(self.player.standing)
        end
    end
end

-- rrerr
local Player = Object:extend()

-- HMMMM..... THAT'S TASTY GAME DEV............
function Player:new(x, y)
    local w, h = 32, 128
    -- define components
    self.collider = colliders.Collider(x, y, w, h)
    self.collider:setCallback(function (colliding_side, obj)
        -- note: self is closed in here, it's not a parameter
        self.state:onCollision(colliding_side, obj)
    end)
    self.collider:setTag("player")
    self.collider:setParent(self)
    collisionHandler:add(self.collider)
    self.sprite = sprite.AnimatedSprite(130, 152, "assets/images/swallow.png", x, y, 65, 23, w)
    -- register animations
    for i=1, 5 do
        self.sprite:addAnimation("stand" .. i, 9, i, 1)
        self.sprite:addAnimation("run" .. i, "1-8", i, 0.075)
        self.sprite:addAnimation("jump" .. i, "10-11", i, 0.05, "pauseAtEnd")
        self.sprite:addAnimation("fall" .. i, 10, i, 1)
    end
    -- how many people's worth of weight we're carrying
    self.fullness = 0
    -- speed stuff
    self.runSpeed = MAX_SPEED
    self.velocity = vector(0, 0)
    -- acceleration stuff
    self.acceleration = MAX_ACCELERATION
    -- jump counter, decrements on jump, resets on hitting the ground
    self.jumpsLeft = MAX_JUMPS
    -- player states
    self.standing = StandingState(self)
    self.running = RunningState(self)
    self.jumping = JumpingState(self)
    self.falling = FallingState(self)
    self.state = self.standing
    -- what's our current animation
    self.currentAnimation = "stand"
    -- are we on the ground?
    self.grounded = false
end

function Player:update(dt)
    self.state:update(dt)
end

function Player:draw()
    -- the collision handler can move the player so this can't be in update anymore
    -- i dont think it really belongs here either tho....
    self.sprite:setPos(self.collider.pos.x, self.collider.pos.y)
    self.sprite:draw()
end

function Player:keyPressed(key)
    self.state:keyPressed(key)
end

-- switch to the given state and run its enter() function
function Player:setState(new_state)
    self.state = new_state
    self.state:enter()
end

-- wraps sprite:setAnimation so we can handle rows automatically
function Player:setAnimation(name)
    local fullness_level = 1 + math.floor((self.fullness + 1) / 3)
    self.currentAnimation = name
    self.sprite:setAnimation(name .. fullness_level)
end

-- increase velocity by the given amount, bound by our current run speed
function Player:accelerate(a)
    local capped_right = math.min(self.velocity.x + a, self.runSpeed)
    self.velocity.x = math.max(capped_right, -self.runSpeed)
end

-- u r now entering the vore zone
function Player:eat(prey)
    local weight = prey:getWeight()
    local new_fullness = self.fullness + weight
    -- do nothing if we don't have room
    if new_fullness > MAX_CAPACITY then
        return
    end
    -- remove prey
    prey:remove()
    -- update player
    self.fullness = new_fullness
    self.runSpeed = self.runSpeed - SPEED_PENALTY * weight
    self.acceleration = self.acceleration - ACC_PENALTY * weight
    -- this is kinda gross but i'll change it when i add rescue anims anyway
    self.jumping.jumpSpeed = self.jumping.jumpSpeed - JUMP_SPEED_PENALTY * weight
    -- update sprite
    local frame_time = self.sprite:getTime()
    self:setAnimation(self.currentAnimation)
    self.sprite:setTime(frame_time)
end

function Player:isFull()
    return self.fullness > MAX_CAPACITY
end

-- used to tell the camera where to look
function Player:getPos()
    return self.collider:getCenter()
end

function Player:__tostring()
    return "Player"
end

return Player
