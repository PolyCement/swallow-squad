local sprite = require "engine.sprite"
local TestZone = require "scenes.test_zone"
local NorthCity = require "scenes.north_city"

-- it's the main menu!
local MainMenu = {}

local center_x = love.graphics.getWidth() / 2

-- i feel like there's a better way to do this probably? im not good at lua
local title_y = 150
local subtitle_font = love.graphics.newFont(32)
local subtitle_text = "Hit enter to start!"
local subtitle_x = center_x - (subtitle_font:getWidth(subtitle_text) / 2)
local subtitle_y = love.graphics.getHeight() - (title_y + subtitle_font:getHeight(subtitle_text))

function MainMenu:enter()
    love.graphics.setBackgroundColor(230, 230, 230)
    clouds = sprite.Sprite("assets/images/bg_cloud.png")
    -- define the title sprite then use its width to set its x pos
    title = sprite.Sprite("assets/images/title.png")
    local title_x = center_x - (title:getWidth() / 2)
    title:setPos(title_x, title_y)
end

function MainMenu:draw()
    clouds:draw()
    title:draw()
    love.graphics.setColor(0, 0, 0, 255)
    love.graphics.setFont(subtitle_font)
    love.graphics.print(subtitle_text, subtitle_x, subtitle_y)
    love.graphics.setColor(255, 255, 255, 255)
end

function MainMenu:keypressed(key)
    if key == "return" then
        Gamestate.switch(NorthCity)
    -- secret!
    elseif debug and key == "t" then
        Gamestate.switch(TestZone)
    end
end

return MainMenu
