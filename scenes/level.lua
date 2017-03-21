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

-- monkey patch to add something resembling python's startswith
function string.starts(str, sub_str)
   return string.sub(str, 1, string.len(sub_str)) == sub_str
end

-- and another to add a split function
function string.split(str, delimiter)
    local delimiter, fields = delimiter or ",", {}
    local pattern = "([^" .. delimiter.. "]+)"
    string.gsub(str, pattern, function(x) table.insert(fields, x) end)
    return fields
end

-- loads map geometry into the collision handler
function loadGeometry(filename)
    -- open the file
    f = io.open(filename, "r")
    for line in f:lines() do
        -- treat lines starting with # as a comment (ie. skip it)
        if not string.starts(line, "#") then
            -- read the fields to a table
            local fields = string.split(line)
            for idx = 2, #fields do
                fields[idx] = tonumber(fields[idx])
            end
            -- the first field determines the collider type
            if fields[1] == "c" then
                -- standard collider
                collisionHandler:add(Collider(true, unpack(fields, 2)))
            elseif fields[1] == "p" then
                -- one-way platform
                collisionHandler:add(Platform(unpack(fields, 2)))
            elseif fields[1] == "r" then
                -- rectangular collider
                table.insert(fields, true)
                collisionHandler:add(RectangleCollider(unpack(fields, 2)))
            end
        end
    end
    f:close()
end
