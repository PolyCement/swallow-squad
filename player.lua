-- rrerr
Player = RectangleCollider:extend()

-- HMMMM..... THAT'S TASTY GAME DEV............
function Player:new(x, y)
    Player.super.new(self, x, y, 48, 112)
    self.width = self.vertices[3].x - self.vertices[1].x
    -- velocity
    self.velocity = {x = 0, y = 0}
    -- sprite
    self.sprite = Sprite("assets/swallow_16.png", self.x, self.y, nil, nil, 64, 8)
    -- speed stuff
    self.maxSpeed = 12*meter
    local min_speed = self.maxSpeed/3
    local max_capacity = 12
    self.speedPenalty = (self.maxSpeed - min_speed)/max_capacity
    -- acceleration stuff
    self.acceleration = 8*meter
    local min_acceleration = self.acceleration/3
    self.accPenalty = (self.acceleration - min_acceleration)/max_capacity
    -- jump stuff
    self.jumpSpeed = 14*meter
    local min_jump_speed = self.jumpSpeed/2
    self.jumpSpeedPenalty = (self.jumpSpeed - min_jump_speed)/max_capacity
    self.maxJumps = 2
    self.jumpsLeft = self.maxJumps
    self.landed = false
end

function Player:update(dt)
    -- mess with the player's velocity
    if self.landed then
        -- if we're touching the ground, accelerate
        if love.keyboard.isDown("left") then
            self:accelerate(-self.acceleration*dt)
            if not self.sprite:isMirrored() then
                self.sprite:flip(self.width)
            end
        elseif love.keyboard.isDown("right") then
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
        end
        self.landed = false -- always assume we're not touching the ground
    else
        -- while airbourne, allow the player to influence their speed a little
        if love.keyboard.isDown("left") then
            self:accelerate(-self.acceleration*dt)
        elseif love.keyboard.isDown("right") then
            self:accelerate(self.acceleration*dt)
        end
    end

    -- update x pos
    local dx = self.velocity.x * dt

    -- update y pos
    self.velocity.y = self.velocity.y + gravity * dt
    local dy = self.velocity.y * dt

    -- print("(" .. self.velocity.x .. ", " .. self.velocity.y .. ")")

    -- attempt to move
    self:move(dx, dy)

    -- update sprite position
    self.sprite:setPos(self.x, self.y)
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
--     print("=====")
--     for _, v in pairs(self.vertices) do
--         print(v)
--     end
    if obj:is(Prey) then
        print("tasty!")
        -- slow down if we eat something
        self.maxSpeed = self.maxSpeed - self.speedPenalty
        self.jumpSpeed = self.jumpSpeed - self.jumpSpeedPenalty
        self.acceleration = self.acceleration - self.accPenalty
    end
    if obj:isSolid() then
        if colliding_side == side.bottom then
            self.landed = true
            -- so i guess the player handles its own physics (for now)
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

-- increase velocity by the given amount, bound by +-maxSpeed
function Player:accelerate(a)
    local capped_right = math.min(self.velocity.x + a, self.maxSpeed)
    self.velocity.x = math.max(capped_right, -self.maxSpeed)
end

function Player:getPos()
    return self.vertices[1]:unpack()
end

function Player:__tostring()
    return "Player"
end
