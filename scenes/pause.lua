local Object = require "lib.classic"
local sprite = require "engine.sprite"
local suit = require "lib.suit"

-- adjust suit theme
suit.theme.cornerRadius = 0
suit.theme.color = {
    normal  = {bg = {225,196, 35}, fg = {  0,  0,  0}},
    hovered = {bg = {225,165, 35}, fg = {  0,  0,  0}},
    active  = {bg = {255,238,140}, fg = {  0,  0,  0}}
}

-- it's a pause menu
local Pause = Object:extend()

function Pause:enter(previous)
    -- keep track of the previous scene so we can keep drawing it in the background
    self.previous = previous
    -- dimensions...
    self.padding = 10
    self.buttonW = 300
    self.buttonH = 50
    self.width = self.buttonW + self.padding * 2
    self.height = (self.buttonH + self.padding) * 5
    self.x = (love.graphics.getWidth() - self.width) / 2
    self.y = (love.graphics.getHeight() - self.height) / 2
    -- load up the blades
    local blade_overhang = 40
    local blade_left_x = self.x - blade_overhang
    self.bladeLeft = sprite.Sprite("assets/images/gui_blade.png", blade_left_x, self.y)
    self.bladeLeft:flip()
    self.bladeLeft:flip("vertical")
    self.bladeRight = sprite.Sprite("assets/images/gui_blade.png")
    local blade_right_x = self.x + self.width + blade_overhang - self.bladeRight:getWidth()
    self.bladeRight:setPos(blade_right_x, self.y)
    self.bladeRight:flip("vertical")
    self.bladeCenter = sprite.Sprite("assets/images/gui_center.png")
    local blade_center_x = self.x + (self.width - self.bladeCenter:getWidth()) / 2
    self.bladeCenter:setPos(blade_center_x, self.y - 2)
    -- what action should be performed
    self.action = nil
end

function Pause:update(dt)
    -- suit updates before pause so we gotta give suit a chance to register buttons being released
    -- so we respond to events one cycle after checking em
    if self.action == "resume" then
        Gamestate.pop()
    elseif self.action == "restart" then
        Gamestate.switch(self.previous)
    elseif self.action == "return" then
        Gamestate.switch(MainMenu)
    elseif self.action == "quit" then
        love.event.quit()
    end

    -- define menu
    suit.layout:reset(self.x + self.padding, self.y, 0, self.padding)
    suit.Label("PAUSED", suit.layout:row(self.buttonW, self.buttonH))
    if suit.Button("Resume", suit.layout:row(self.buttonW, self.buttonH)).hit then
        self.action = "resume"
    elseif suit.Button("Restart", suit.layout:row(self.buttonW, self.buttonH)).hit then
        self.action = "restart"
    elseif suit.Button("Quit to Menu", suit.layout:row(self.buttonW, self.buttonH)).hit then
        self.action = "return"
    elseif suit.Button("Quit to Desktop", suit.layout:row(self.buttonW, self.buttonH)).hit then
        self.action = "quit"
    end
end

function Pause:draw()
    -- draw background scene
    self.previous:draw()
    -- draw window background
    love.graphics.setColor(0, 0, 0, 255)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
    love.graphics.setColor(255, 255, 255, 255)
    -- draw blades
    self.bladeLeft:draw()
    self.bladeRight:draw()
    self.bladeCenter:draw()
    -- draw gui
    suit.draw()
end

function Pause:keypressed(key)
    -- escape to unpause
    if key == "escape" then
        Gamestate.pop()
    end
end

return Pause
