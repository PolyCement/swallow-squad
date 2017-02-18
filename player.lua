-- rrerr
Player = RectangleCollider:extend()

-- keeping these constants out here for now so i can mess with em more easily
-- i don't feel like they were any better off as instance variables anyway?
local MAX_CAPACITY = 12

-- speed constants
local MAX_SPEED = 16 * METER
local MIN_SPEED = MAX_SPEED * .5
local SPEED_PENALTY = (MAX_SPEED - MIN_SPEED) / MAX_CAPACITY

-- acceleration constants
local MAX_ACCELERATION = 16 * METER
local MIN_ACCELERATION = MAX_ACCELERATION * .5
local ACC_PENALTY = (MAX_ACCELERATION - MIN_ACCELERATION) / MAX_CAPACITY

-- jump constants
local MAX_JUMP_SPEED = 12 * METER
local MIN_JUMP_SPEED = MAX_JUMP_SPEED * .75
local JUMP_SPEED_PENALTY = (MAX_JUMP_SPEED - MIN_JUMP_SPEED) / MAX_CAPACITY
local MAX_TIME_JUMPING = .5
local MAX_JUMPS = 2

-- HMMMM..... THAT'S TASTY GAME DEV............
function Player:new(x, y)
    local width = 32
    Player.super.new(self, x, y, width, 128)
    -- sprite
    self.sprite = AnimatedSprite("assets/swallow_empty.png",
                                 self.vertices[1].x, self.vertices[1].y, nil, nil, 58, 11, width)
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
    -- where was our bottom edge before we moved? (used for one-way platforms)
    self.prevBottomPos = (self.vertices[3] + self.vertices[4]) / 2
end

function Player:update(dt)
    -- mess with the player's velocity
    if self.landed then
        -- if we're touching the ground, accelerate
        if love.keyboard.isDown("left") then
            if self.sprite.stopped then
                self.sprite:resume()
            end
            self:accelerate(-self.acceleration*dt)
            if not self.sprite:isMirrored() then
                self.sprite:flip()
            end
        elseif love.keyboard.isDown("right") then
            if self.sprite.stopped then
                self.sprite:resume()
            end
            self:accelerate(self.acceleration*dt)
            if self.sprite:isMirrored() then
                self.sprite:flip()
            end
        else
            -- we have contact with the floor so decelerate
            if self.velocity.x > 1 then
                self:accelerate(-self.acceleration*dt)
            elseif self.velocity.x < -1 then
                self:accelerate(self.acceleration*dt)
            else
                -- no jigglin
                self.velocity.x = 0
            end
            -- NO JIGGLIN
            -- todo: remove jiggle
            self.sprite:stop()
        end
        self.landed = false -- always assume we're not touching the ground
    else
        -- hi this should play a wing flapping animation but i dont have one so it just, stops
        -- self.sprite:pause()
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
    end

    -- update pos
    -- we're using double gravity cos at this scale standard gravity is super floaty
    self.velocity.y = self.velocity.y + gravity * 2 * dt
    local delta = self.velocity * dt

    -- attempt to move
    self.prevBottomPos = (self.vertices[3] + self.vertices[4]) / 2
    self:move(delta)

    -- update sprite (we manipulate it into updating faster or slower by tampering with dt)
    local animation_coefficient = math.abs(self.velocity.x) / MAX_SPEED
    self.sprite:update(dt * animation_coefficient)
    self.sprite:setPos(self.vertices[1]:unpack())
end

function Player:draw()
    Player.super.draw(self)
    self.sprite:draw()
end

function Player:keyPressed(key)
    -- jumping from the ground is free, only air jumps should decrement the counter
    if key == "space" then
        if not self.landed then
            self.jumpsLeft = self.jumpsLeft - 1
        end
    end
end

function Player:keyReleased(key)
    if key == "space" then
        self.timeJumping = 0
    end
end

-- collision handling
function Player:onCollision(obj, colliding_side)
    if obj:is(Prey) then
        self:eat(obj.weight)
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
    print("tasty!")
    self.fullness = self.fullness + weight
    -- slow down if we eat something
    self.runSpeed = self.runSpeed - SPEED_PENALTY * weight
    self.jumpSpeed = self.jumpSpeed - JUMP_SPEED_PENALTY * weight
    self.acceleration = self.acceleration - ACC_PENALTY * weight
    -- change sprite when we're full
    -- commented out because it makes the game crash!!!
    if self.fullness >= 12 then
        self:updateSprite("assets/swallow_fullest.png")
    elseif self.fullness >= 9 then
        self:updateSprite("assets/swallow_fullerer.png")
    elseif self.fullness >= 6 then
        self:updateSprite("assets/swallow_fuller.png")
    elseif self.fullness >= 3 then
        self:updateSprite("assets/swallow_full.png")
    end
end

function Player:updateSprite(new_sprite)
    local is_mirrored = self.sprite:isMirrored()
    local flip_offset = self.vertices[3].x - self.vertices[1].x
    self.sprite = Sprite(new_sprite, self.vertices[1].x, self.vertices[1].y, nil, nil, 64, 0, flip_offset)
    if is_mirrored then
        self.sprite:flip()
    end
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

function Player:__tostring()
    return "Player"
end
