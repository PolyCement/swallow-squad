-- parser for tiled output in json format
local Object = require "lib.classic"
local json = require "lib.json"
local colliders = require "engine.colliders"

-- takes b, a relative path in the file given by path a
-- and adjusts it to be relative to the root of path a
-- (it's a tricky one to explain but like.... it's important ok)
local function adjust_path(a, b)
    -- strip filename from a
    a = a:gsub("[^/]+$", "")
    -- for each .. in b, strip it, and strip the bottom level from a
    while b:find("^%.%./") do
        b = b:gsub("^%.%./", "")
        a = a:gsub("[^/]+/?$", "")
    end
    -- add a slash to the end of a if we need one
    a = a .. (a:find("/$") and "/" or "")
    return a .. b
end

-- strip bits used to indicated flippedness from the given gid
local FLIP_H_FLAG = 0x80000000
local FLIP_V_FLAG = 0x40000000
local FLIP_D_FLAG = 0x20000000
local function strip_flip(gid)
    return bit.band(gid, bit.bnot(bit.bor(FLIP_H_FLAG, FLIP_V_FLAG, FLIP_D_FLAG)))
end

-- ok world really needs to be an object
-- only available by calling TiledMap:getWorld()
-- takes a map and pulls out all the stuff needed for collisions
-- NOTE: does NOT handle transforms - it's more trouble than its worth
-- todo: really not happy about collision and image tiles being the same
-- there's gotta be a way to separate em when loading the map
local World = Object:extend()

function World:new(map)
    self.tileWidth = map.tileWidth
    self.tileHeight = map.tileHeight
    -- self.world is map.layers.world with tiles subbed in directly
    -- (we can't do this for drawing cos of flips)
    -- ideally these would be some kind of collision-specific tile rather than
    -- the all-purpose ones we have now - world really shouldn't know about image stuff
    -- not to mention how this gives collisionhandler indirect access to tilesets.......
    self.world = {}
    for idx, gid in pairs(map.layers.world.data) do
        local x = ((idx - 1) % map.width)
        local y = math.floor((idx - 1) / map.width)
        if not self.world[x] then
            self.world[x] = {}
        end
        self.world[x][y] = map.tiles[gid]
    end
end

-- maps have layers, like an onion
local Layer = Object:extend()

function Layer:new(raw)
    self.data = raw.data
    self.visible = raw.visible
    self.name = raw.name
    self.alpha = raw.opacity * 255
end

-- a tile - holds a quad, a reference to its parent tileset, and collision data
local Tile = Object:extend()

function Tile:new(quad, tileset, raw, props)
    self.quad = quad
    self.tileset = tileset
    self.collisionType = raw and raw.type or nil
    if self.collisionType == "ramp" then
        self.y = {left = props.y_left or 0, right = props.y_right or 0}
    end
end

-- shit i guess i gotta parse tilesets too
local Tileset = Object:extend()

function Tileset:new(tileset_path)
    -- open up the tileset file and pull out The Good Shit
    local raw = json.decode(love.filesystem.read(tileset_path))
    local tw, th, iw, ih = raw.tilewidth, raw.tileheight, raw.imagewidth, raw.imageheight
    self.image = love.graphics.newImage(adjust_path(tileset_path, raw.image))
    self.tileWidth = tw
    self.tileHeight = th
    self.imageWidth = iw
    self.imageHeight = ih
    
    -- make a tile object for each tile in the set
    -- note: these are indexed from 0
    self.tiles = {}
    local idx = 0
    for y = 0, self.imageHeight - 1, self.tileHeight do
        for x = 0, self.imageWidth - 1, self.tileWidth do
            local tile_quad = love.graphics.newQuad(x, y, tw, th, iw, ih)
            local raw_tile = raw.tiles and raw.tiles[tostring(idx)] or nil
            local props = raw.tileproperties and raw.tileproperties[tostring(idx)] or nil
            self.tiles[idx] = Tile(tile_quad, self, raw_tile, props)
            idx = idx + 1
        end
    end
end

-- here is the map, where do u wish to go
-- the physical tile layer should be named "world"
local TiledMap = Object:extend()

function TiledMap:new(map_path)
    -- crack that bad boy open
    local raw = json.decode(love.filesystem.read(map_path))

    self.width = raw.width
    self.height = raw.height
    self.tileWidth = raw.tilewidth
    self.tileHeight = raw.tileheight

    -- load layers
    -- maybe objects should be kept in layers? i'll figure it out later
    self.layers = {}
    self.objects = {}
    for _, raw_layer in pairs(raw.layers) do
        local layer_type = raw_layer.type
        if layer_type == "tilelayer" then
            self.layers[raw_layer.name] = Layer(raw_layer)
        elseif layer_type == "objectgroup" then
            for _, obj in pairs(raw_layer.objects) do
                table.insert(self.objects, obj)
            end
        end
    end

    -- load tilesets
    self.tiles = {}
    self.tilesets = {}
    for _, tileset in pairs(raw.tilesets) do
        local first_gid = tileset.firstgid
        local new_tileset = Tileset(adjust_path(map_path, tileset.source))
        table.insert(self.tilesets, new_tileset)
        -- throw the new tiles on the map's tile pile
        for idx, tile in pairs(new_tileset.tiles) do
            self.tiles[first_gid + idx] = tile
        end
    end
end

-- ideally layer would just have a draw function
-- but layers dont actually know about tilesets, gids, etc
local function draw_layer(self, layer)
    for idx, gid in pairs(layer.data) do
        -- skip blanks
        love.graphics.setColor(255, 255, 255, layer.alpha)
        if gid ~= 0 then
            -- check for flip bits, then strip em
            local flipped_h = bit.band(gid, FLIP_H_FLAG) ~= 0
            local flipped_v = bit.band(gid, FLIP_V_FLAG) ~= 0
            local flipped_d = bit.band(gid, FLIP_D_FLAG) ~= 0
            gid = strip_flip(gid)
            -- grab the tile's quad and its tileset's image
            local tile_quad = self.tiles[gid].quad
            local tile_image = self.tiles[gid].tileset.image
            -- determine draw position
            local x = ((idx - 1) % self.width) * self.tileWidth
            local y = math.floor((idx - 1) / self.width) * self.tileHeight
            local draw_y = y
            -- handle any potential flips
            local r, sx, sy = 0, 1, 1
            sx = flipped_h and -sx or sx
            sy = flipped_v and -sy or sy
            if flipped_d then
                -- to flip anti-diagonally we need to rotate 90 degrees, then flip vertically
                -- thing is, love.graphics.draw does rotation LAST
                -- so to compensate, we have to invert sy, then swap sx and sy
                local old_sx = sx
                sx = -sy
                sy = old_sx
                -- the acrobatics above means we now have to rotate -90 degrees instead
                r = -math.pi/2
                -- also there's no way to rotate in place without screwing with draw pos :/
                y = y + self.tileHeight
            end
            -- set offsets
            local ox = sx > 0 and 0 or self.tileWidth
            local oy = sy > 0 and 0 or self.tileHeight
            -- now do a draw
            love.graphics.draw(tile_image, tile_quad, x, y, r, sx, sy, ox, oy)
        end
        love.graphics.setColor(255, 255, 255, 255)
    end
end

function TiledMap:draw()
    for _, layer in pairs(self.layers) do
        if layer.visible or (layer.name == "world" and showColliders) then
            draw_layer(self, layer)
        end
    end
end

-- returns a world object containing collision info
function TiledMap:getWorld()
    return World(self)
end

-- returns a table of all objects
function TiledMap:getObjects()
    return self.objects
end

return TiledMap
