-- it's the main menu!
main_menu = {}

local center_x = love.graphics.getWidth() / 2

-- i feel like there's a better way to do this probably? im not good at lua
local title_y = 150
local subtitle_font = love.graphics.newFont(32)
local subtitle_text = "Hit enter to start!"
local subtitle_x = center_x - (subtitle_font:getWidth(subtitle_text) / 2)
local subtitle_y = love.graphics.getHeight() - (title_y + subtitle_font:getHeight(subtitle_text))

function main_menu:enter()
    love.graphics.setBackgroundColor(230, 230, 230)
    clouds = Sprite("assets/images/bg_cloud.png")
    -- define the title sprite then use its width to set its x pos
    title = Sprite("assets/images/title.png")
    local title_x = center_x - (title:getWidth() / 2)
    title:setPos(title_x, title_y)
end

function main_menu:draw()
    clouds:draw()
    title:draw()
    love.graphics.setColor(0, 0, 0, 255)
    love.graphics.setFont(subtitle_font)
    love.graphics.print(subtitle_text, subtitle_x, subtitle_y)
    love.graphics.setColor(255, 255, 255, 255)
end

function main_menu:keypressed(key)
    if key == "return" then
        Gamestate.switch(north_city)
    -- secret!
    elseif debug and key == "t" then
        Gamestate.switch(test_zone)
    end
end
