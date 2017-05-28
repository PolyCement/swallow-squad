require "colliders.collider"
require "engine.animated_sprite"
local Object = require "lib.classic"
local survivors = require "actors.prey"

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
    self.player.velocity.y = self.player.velocity.y + gravity * dt
    -- update position
    local delta = self.player.velocity * dt
    -- attempt to move
    self.player.prevBottomPos = (self.player.vertices[3] + self.player.vertices[4]) / 2
    self.player:move(delta)
end

function PlayerState:keyPressed(key)
end

function PlayerState:onCollision(obj, colliding_side)
    if obj:is(survivors.Prey) then
        self.player:eat(obj:getWeight())
    end
    if obj:isSolid() then
        if colliding_side == side.bottom or colliding_side == side.top then
            self.player.velocity.y = 0
        elseif colliding_side == side.left or colliding_side == side.right then
            self.player.velocity.x = 0
        end
    end
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
    -- if we're falling (ie. we've left the ground) attempt to snap to it
    if self.player.velocity.y > 0 then
        self.player:snapToGround()
    end
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
    if self.player.velocity.y > 0 then
        self.player:snapToGround()
    end
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

function JumpingState:onCollision(obj, colliding_side)
    JumpingState.super.onCollision(self, obj, colliding_side)
    if obj:isSolid() then
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

function FallingState:onCollision(obj, colliding_side)
    FallingState.super.onCollision(self, obj, colliding_side)
    if obj:isSolid() then
        if colliding_side == side.bottom then
            self.player:setState(self.player.standing)
        end
    end
end

-- rrerr
Player = Collider:extend()

-- HMMMM..... THAT'S TASTY GAME DEV............
function Player:new(x, y)
    local width = 32
    local x2 = x + width
    local y2 = y + 128
    Player.super.new(self, true, x, y, x2, y, x2, y2, x, y2)
    -- sprite
    self.sprite = AnimatedSprite(130, 152, "assets/images/swallow.png",
                                 self.vertices[1].x, self.vertices[1].y, 65, 23, width)
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
    -- where was our bottom edge before we moved? (used for one-way platforms)
    self.prevBottomPos = (self.vertices[3] + self.vertices[4]) / 2
    -- what's our current animation
    self.currentAnimation = "stand"
end

function Player:update(dt)
    self.state:update(dt)
    self.sprite:setPos(self.vertices[1]:unpack())
end

function Player:draw()
    self.sprite:draw()
end

function Player:keyPressed(key)
    self.state:keyPressed(key)
end

function Player:onCollision(obj, colliding_side)
    self.state:onCollision(obj, colliding_side)
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
function Player:eat(weight)
    self.fullness = self.fullness + weight
    -- apply movement penalties
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
    return self:getCenter()
end

-- used to keep the player stuck to slopes
function Player:snapToGround()
    -- cast a tiny ray from our back edge
    local back_corner = nil
    if self.velocity.x < 0 then
        back_corner = self.vertices[3]
    else
        back_corner = self.vertices[4]
    end
    -- 8 is a long beam but needed to handle ~45 degree slopes while empty
    local ray_end = back_corner + vector(0, 8)
    local collisions = collisionHandler:raycast(back_corner, ray_end)
    -- if there's a platform close to the player's feet, pull em down
    if #collisions > 0 then
        local segment, intersect = collisions[1][1], collisions[1][2]
        -- don't do anything if we're not actually going down the slope
        -- (this fixes issues with the ray catching a slight slope while ascending)
        if (self.velocity.x < 0) ~= (segment.normal.x < 0) then
            local delta = vector(0, intersect.y - back_corner.y)
            self:move(delta)
            -- rounding means we might not quite touch the slope
            -- so we gotta reset y velocity to stop us immediately entering the fall state
            self.velocity.y = 0
        end
    end
end

function Player:__tostring()
    return "Player"
end
