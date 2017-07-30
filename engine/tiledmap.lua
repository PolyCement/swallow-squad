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

local FLIP_H_FLAG = 0x80000000
local FLIP_V_FLAG = 0x40000000
local FLIP_D_FLAG = 0x20000000
-- strip bits used to indicated flippedness from the given gid
-- todo: replace all these bit calls if löve ever switches to lua 5.3
local function strip_flip(gid)
    return bit.band(gid, bit.bnot(bit.bor(FLIP_H_FLAG, FLIP_V_FLAG, FLIP_D_FLAG)))
end

-- ok world really needs to be an object
-- only available by calling TiledMap:getWorld()
-- takes a map and pulls out all the stuff needed for collisions
-- will definitely end up changing once i add slopes but i need some structure first
local World = Object:extend()

function World:new(map)
    self.tileWidth = map.tileWidth
    self.tileHeight = map.tileHeight
    self.world = {}
    for _, layer in pairs(map.layers) do
        if layer.name == "base" then
            for idx, gid in pairs(layer.data) do
                local x = ((idx - 1) % map.width)
                local y = math.floor((idx - 1) / map.width)
                if not self.world[x] then
                    self.world[x] = {}
                end
                gid = strip_flip(gid)
                if gid ~= 0 and map.tiles[gid].collisionType == "block" then
                    self.world[x][y] = true
                else
                    self.world[x][y] = false
                end
            end
        end
    end
end

-- maps have layers, like an onion
local Layer = Object:extend()

function Layer:new(raw)
    self.data = raw.data
    self.visible = raw.visible
    self.name = raw.name
end

-- a tile. holds a quad and reference to its parent tileset for drawing
-- also holds any necessary collision data
local Tile = Object:extend()

function Tile:new(raw, quad, tileset)
    self.quad = quad
    self.tileset = tileset
    self.collisionType = raw and raw.type or nil
    -- slope stuff goes here when i get round to adding it
    -- (that's kinda the whole reason for passing the raw tile info instead of just "type")
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
            local raw_tile = raw.tiles[tostring(idx)]
            self.tiles[idx] = Tile(raw_tile, tile_quad, self)
            idx = idx + 1
        end
    end
end

-- here is the map, where do u wish to go
local TiledMap = Object:extend()

function TiledMap:new(map_path)
    -- crack that bad boy open
    local raw = json.decode(love.filesystem.read(map_path))

    self.width = raw.width
    self.height = raw.height
    self.tileWidth = raw.tilewidth
    self.tileHeight = raw.tileheight

    -- load layers
    self.layers = {}
    for _, raw_layer in pairs(raw.layers) do
        table.insert(self.layers, Layer(raw_layer))
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

-- flags for checking flippedness: horizontal, vertical, anti-diagonal
function TiledMap:draw()
    for _, layer in pairs(self.layers) do
        for idx, gid in pairs(layer.data) do
            -- skip blanks
            if gid ~= 0 then
                -- handle flips
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
                -- draw a traslucent rectangle over blocks
                if showColliders and self.tiles[gid].collisionType == "block" then
                    love.graphics.setColor(255, 0, 0, 128)
                    love.graphics.rectangle("fill", x, draw_y, self.tileWidth, self.tileHeight)
                    love.graphics.setColor(255, 255, 255, 255)
                end
            end
        end
    end
end

-- returns a world object containing collision info
function TiledMap:getWorld()
    return World(self)
end

return TiledMap
