require "engine.patches"
Gamestate = require "lib.hump.gamestate"
-- if this isn't a global i have to import it in pause and north_city, which becomes cyclic
-- todo: fix that
MainMenu = require "scenes.main_menu"

function love.load()
    -- disable antialiasing
    love.graphics.setDefaultFilter("nearest", "nearest")
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
    -- todo: full-blown fixed timestep?
    local old_update = love.update
    love.update = function(dt)
        -- if dt is too big do multiple updates
        local time_left = dt
        while time_left > 0 do
            dt = math.min(0.01, time_left)
            time_left = time_left - dt
            old_update(dt)
        end
    end

    -- start at main menu
    Gamestate.switch(MainMenu)
end
