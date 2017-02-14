Gamestate = require "lib.hump.gamestate"
require "scenes.test_zone"
require "scenes.main_menu"
require "scenes.north_city"

function love.load()
    Gamestate.registerEvents()
    Gamestate.switch(main_menu)
end

function love.keypressed(key)
    -- esc to quit
    if key == "escape" then
        love.event.quit()
    end
end
