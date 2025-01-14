-- https://www.reddit.com/r/awesomewm/comments/io42o2/simplest_vertical_tiling/
--
local pairs = pairs

local vert_tile = {}

vert_tile.name = "vertical"
function vert_tile.arrange(p)
    local area
    area = p.workarea
    local i = 0
    for _, c in pairs(p.clients) do
            local g = {
                    y = area.y,
                    x = area.x + i * (area.width / #p.clients),
                    width = area.width / #p.clients,
                    height = area.height,
            }
            p.geometries[c] = g
            i = i + 1
    end
end

return vert_tile
