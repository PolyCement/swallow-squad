-- stuff common to all levels will end up here once i figure out what that actually is
-- maybe it should be some kind of template rather than a class
-- levels should extend this
Level = Object:extend()

-- debug: prints the coordinate under the cursor (for placing world geometry)
function Level:mousemoved(x, y)
    if showMousePos then
        local adjusted_x = x - love.graphics.getWidth() / 2
        local adjusted_y = y - love.graphics.getHeight() / 2
        local cam_x, cam_y = camera:position()
        print(math.floor(adjusted_x + cam_x), math.floor(adjusted_y + cam_y))
    end
end

-- loads map geometry into the collision handler
-- eventually this will load geometry from a file instead of being passed a table
function initGeometry(colliders)
    -- register level geometry with collision handler
    for _, v in pairs(colliders) do
        collisionHandler:add(v)
    end
end
