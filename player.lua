-- rrerr
Player = RectangleCollider:extend()

-- HMMMM..... THAT'S TASTY GAME DEV............
function Player:new(x, y)
    self.width = 32
    Player.super.new(self, x, y, self.width, 128)
    -- sprite
    self.sprite = AnimatedSprite("assets/swallow_empty.png",
                                 self.vertices[1].x, self.vertices[1].y, nil, nil, 58, 0)
    -- how many people's worth of weight we're carrying
    self.fullness = 0
    local max_capacity = 12
    -- speed stuff
    self.velocity = vector(0, 0)
    self.maxSpeed = 12*meter
    local min_speed = self.maxSpeed/2
    self.speedPenalty = (self.maxSpeed - min_speed)/max_capacity
    -- acceleration stuff
    self.acceleration = 16*meter
    local min_acceleration = self.acceleration/2
    self.accPenalty = (self.acceleration - min_acceleration)/max_capacity
    -- jump stuff
    -- i gotta figure out how to make this work based on height rather than speed
    self.jumpSpeed = 14*meter
    local min_jump_speed = self.jumpSpeed*.75
    self.jumpSpeedPenalty = (self.jumpSpeed - min_jump_speed)/max_capacity
    self.maxJumps = 2
    self.jumpsLeft = self.maxJumps
    -- have we hit the ground this cycle?
    self.landed = false
    -- animation speed, might move this later
    self.animationVelocity = self.maxSpeed
end

function Player:update(dt)
    -- mess with the player's velocity
    if self.landed then
        -- if we're touching the ground, accelerate
        if love.keyboard.isDown("left") then
            self.sprite:resume()
            self:accelerate(-self.acceleration*dt)
            if not self.sprite:isMirrored() then
                self.sprite:flip(self.width)
            end
        elseif love.keyboard.isDown("right") then
            self.sprite:resume()
            self:accelerate(self.acceleration*dt)
            if self.sprite:isMirrored() then
                self.sprite:flip(self.width)
            end
        else
            -- we have contact with the floor so dampen x velocity too
            if self.velocity.x > 0.5 then
                self:accelerate(-self.acceleration*dt)
            elseif self.velocity.x < -0.5 then
                self:accelerate(self.acceleration*dt)
            else
                -- no jigglin
                self.velocity.x = 0
            end
            -- NO JIGGLIN
            self.sprite:stop()
        end
        self.landed = false -- always assume we're not touching the ground
    else
        -- hi this should play a wing flapping animation but i dont have one so it just, stops
        self.sprite:pause()
        -- while airbourne, allow the player to influence their speed a little
        if love.keyboard.isDown("left") then
            self:accelerate(-self.acceleration*dt)
        elseif love.keyboard.isDown("right") then
            self:accelerate(self.acceleration*dt)
        end
    end

    -- update pos
    self.velocity.y = self.velocity.y + gravity * dt
    local delta = self.velocity * dt

    -- attempt to move
    self:move(delta)

    -- update sprite
    -- we can manipulate the sprite into updating faster or slower by tampering with dt
    local animation_coefficient = math.abs(self.velocity.x) / self.animationVelocity
    self.sprite:update(dt * animation_coefficient)
    self.sprite:setPos(self.vertices[1]:unpack())
end

function Player:draw()
    Player.super.draw(self)
    self.sprite:draw()
end

function Player:keyPressed(key)
    -- bounce bounce
    if key == "space" and self.jumpsLeft > 0 then
        self.velocity.y = -self.jumpSpeed
        -- jumping from the ground is free, only air jumps should decrement the counter
        if not self.landed then
            self.jumpsLeft = self.jumpsLeft - 1
        end
    end
end

-- collision handling
function Player:onCollision(obj, colliding_side)
    if obj:is(Prey) then
        self:eat(obj.weight)
    end
    if obj:isSolid() then
        if colliding_side == side.bottom then
            self.landed = true
            -- the player handles its own physics (for now)
            self.velocity.y = 0
            -- reset jump count
            self.jumpsLeft = self.maxJumps
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
    self.maxSpeed = self.maxSpeed - self.speedPenalty
    self.jumpSpeed = self.jumpSpeed - self.jumpSpeedPenalty
    self.acceleration = self.acceleration - self.accPenalty
    -- change sprite when we're full
    -- commented out because it makes the game crash!!!
    -- if self.fullness >= 12 then
        -- self:updateSprite("assets/swallow_fullest.png")
    -- elseif self.fullness >= 9 then
        -- self:updateSprite("assets/swallow_fullerer.png")
    -- elseif self.fullness >= 6 then
        -- self:updateSprite("assets/swallow_fuller.png")
    -- elseif self.fullness >= 3 then
        -- self:updateSprite("assets/swallow_full.png")
    -- end
end

function Player:updateSprite(new_sprite)
    local is_mirrored = self.sprite:isMirrored()
    self.sprite = Sprite(new_sprite, self.vertices[1].x, self.vertices[1].y, nil, nil, 64, 0)
    if is_mirrored then
        self.sprite:flip(self.width)
    end
end

-- increase velocity by the given amount, bound by +-maxSpeed
function Player:accelerate(a)
    local capped_right = math.min(self.velocity.x + a, self.maxSpeed)
    self.velocity.x = math.max(capped_right, -self.maxSpeed)
end

-- used to tell the camera where to look
function Player:getPos()
    return self:getCenter()
end

function Player:__tostring()
    return "Player"
end
