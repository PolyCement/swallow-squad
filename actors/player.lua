require "colliders.collider"
require "engine.animated_sprite"

-- rrerr
Player = Collider:extend()

-- pixels per meter
-- use this to specify things in meters rather than pixels
local METER = 16

-- keeping these constants out here for now so i can mess with em more easily
-- i don't feel like they were any better off as instance variables anyway?
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
local MAX_JUMPS = 2

-- if the player's speed drops below this it's set to 0
local JIGGLE_PREVENTION = 5

-- HMMMM..... THAT'S TASTY GAME DEV............
function Player:new(x, y)
    local width = 32
    local x2 = x + width
    local y2 = y + 128
    Player.super.new(self, true, x, y, x2, y, x2, y2, x, y2)
    -- sprite
    self.sprite = AnimatedSprite(130, 152, "assets/swallow.png",
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
    -- jump stuff
    self.jumpSpeed = MAX_JUMP_SPEED
    self.timeJumping = 0
    self.jumpsLeft = MAX_JUMPS
    -- have we hit the ground this cycle?
    self.landed = false
    -- are we running?
    self.running = false
    -- where was our bottom edge before we moved? (used for one-way platforms)
    self.prevBottomPos = (self.vertices[3] + self.vertices[4]) / 2
    -- what's our current animation
    self.currentAnimation = "stand"
end

function Player:update(dt)
    -- todo: better animation control
    -- mess with the player's velocity
    if self.landed then
        -- if we're touching the ground, run
        if love.keyboard.isDown("left") then
            if not self.running then
                self.running = true
                self:setAnimation("run")
            end
            self:accelerate(-self.acceleration*dt)
            if not self.sprite:isMirrored() then
                self.sprite:flip()
            end
        elseif love.keyboard.isDown("right") then
            self:accelerate(self.acceleration*dt)
            if not self.running then
                self.running = true
                self:setAnimation("run")
            end
            if self.sprite:isMirrored() then
                self.sprite:flip()
            end
        else
            self.running = false
            if self.currentAnimation ~= "stand" then
                self:setAnimation("stand")
            end
            -- we have contact with the floor so decelerate
            if self.velocity.x > JIGGLE_PREVENTION then
                self:accelerate(-self.acceleration*dt)
            elseif self.velocity.x < -JIGGLE_PREVENTION then
                self:accelerate(self.acceleration*dt)
            else
                -- no jigglin
                self.velocity.x = 0
            end
        end
    else
        self.running = false
        -- while airbourne, allow the player to influence their speed a little
        if love.keyboard.isDown("left") then
            self:accelerate(-self.acceleration*.5*dt)
        elseif love.keyboard.isDown("right") then
            self:accelerate(self.acceleration*.5*dt)
        end
    end

    -- bounce bounce
    if love.keyboard.isDown("space") and self.jumpsLeft >= 0
        and self.timeJumping < MAX_TIME_JUMPING then
        self.timeJumping = self.timeJumping + dt
        self.velocity.y = -self.jumpSpeed
    else
        if self.velocity.y > 0 and self.currentAnimation ~= "fall" then
            self:setAnimation("fall")
        end
    end

    -- update pos
    self.velocity.y = self.velocity.y + gravity * dt
    local delta = self.velocity * dt

    -- attempt to move
    self.prevBottomPos = (self.vertices[3] + self.vertices[4]) / 2
    self:move(delta)

    -- update sprite (we manipulate it into updating faster or slower by tampering with dt)
    local animation_coefficient = 1
    if self.running then
         animation_coefficient = math.abs(self.velocity.x) / MAX_SPEED
    end
    self.sprite:update(dt * animation_coefficient)
    self.sprite:setPos(self.vertices[1]:unpack())
end

-- wraps sprite:setAnimation so we can handle rows automatically
function Player:setAnimation(name)
    local fullness_level = 1 + math.floor((self.fullness + 1) / 3)
    self.currentAnimation = name
    self.sprite:setAnimation(name .. fullness_level)
end

function Player:draw()
    self.sprite:draw()
end

function Player:keyPressed(key)
    -- jumping from the ground is free, only air jumps should decrement the counter
    if key == "space" then
        if self.jumpsLeft > 0 then
            self:setAnimation("jump")
        end
        if not self.landed then
            self.jumpsLeft = self.jumpsLeft - 1
        end
        self.landed = false
    end
end

function Player:keyReleased(key)
    if key == "space" then
        self.timeJumping = 0
    end
end

-- collision handling
function Player:onCollision(obj, colliding_side, mtd)
    if obj:is(Prey) then
        self:eat(obj:getWeight())
    end
    if obj:isSolid() then
        if colliding_side == side.bottom then
            self.velocity.y = 0
            self.landed = true
            -- reset jump count
            self.jumpsLeft = MAX_JUMPS
        -- if we hit the side of something kill x velocity
        elseif colliding_side == side.top then
            self.velocity.y = 0
        elseif colliding_side == side.left or colliding_side == side.right then
            self.velocity.x = 0
        end
    end
end

-- u r now entering the vore zone
function Player:eat(weight)
    self.fullness = self.fullness + weight
    -- apply movement penalties
    self.runSpeed = self.runSpeed - SPEED_PENALTY * weight
    self.jumpSpeed = self.jumpSpeed - JUMP_SPEED_PENALTY * weight
    self.acceleration = self.acceleration - ACC_PENALTY * weight
    -- update sprite
    local frame_time = self.sprite:getTime()
    self:setAnimation(self.currentAnimation)
    self.sprite:setTime(frame_time)
end

-- increase velocity by the given amount, bound by our current run speed
function Player:accelerate(a)
    local capped_right = math.min(self.velocity.x + a, self.runSpeed)
    self.velocity.x = math.max(capped_right, -self.runSpeed)
end

-- used to tell the camera where to look
function Player:getPos()
    return self:getCenter()
end

function Player:isFull()
    return self.fullness > MAX_CAPACITY
end

function Player:move(delta)
    local was_landed = self.landed
    self.landed = false 
    -- move as normal
    Player.super.move(self, delta)
    -- if the player becomes airborne and is moving downwards, check what's under em
    if was_landed and not self.landed and self.velocity.y > 0 then
        -- cast a tiny ray from our back edge
        local back_corner = nil
        if self.velocity.x < 0 then
            back_corner = self.vertices[3]
        else
            back_corner = self.vertices[4]
        end
        -- 5 is a pretty long beam but required to handle slopes up to ~45 degrees while empty
        local ray_end = back_corner + vector(0, 8)
        local collisions = collisionHandler:raycast(back_corner, ray_end)
        -- if there's a platform close to the player's feet, pull em down
        if #collisions > 0 then
            local segment, intersect = collisions[1][1], collisions[1][2]
            -- don't do anything if we're not actually going down the slope
            -- (this fixes issues with the ray catching a slight slope while ascending)
            if (self.velocity.x < 0) ~= (segment.normal.x < 0) then
                local delta = vector(0, intersect.y - back_corner.y)
                self:movementHelper(delta)
                self.landed = true
                self.velocity.y = 0
            end
        end
    end
end

function Player:__tostring()
    return "Player"
end
