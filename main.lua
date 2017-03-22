Gamestate = require "lib.hump.gamestate"
require "scenes.test_zone"
require "scenes.main_menu"
require "scenes.north_city"

-- fun with monkey patches, i can't believe i have to define this myself
-- this should probably go somewhere else
function table.length(t)
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

function love.load()
    -- handle args
    debug = false
    for _, a in pairs(arg) do
        if a == "-d" or a == "--debug" then
            debug = true
        end
    end
    Gamestate.registerEvents()
    Gamestate.switch(main_menu)
end

function love.keypressed(key)
    -- esc to quit
    if key == "escape" then
        love.event.quit()
    end
end
