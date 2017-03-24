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
    -- handle command line args
    debug = false
    for _, a in pairs(arg) do
        if a == "-d" or a == "--debug" then
            debug = true
        end
    end

    -- register events
    Gamestate.registerEvents()

    -- wrap love.update in some code that limits dt so we don't fall through the floor
    local old_update = love.update
    love.update = function(dt)
        -- if dt is too big do multiple updates
        local time_left = dt
        while time_left > 0 do
            dt = math.min(0.05, time_left)
            time_left = time_left - dt
            old_update(dt)
        end
    end

    -- start at main menu
    Gamestate.switch(main_menu)
end

function love.keypressed(key)
    -- esc to quit
    if key == "escape" then
        love.event.quit()
    end
end
