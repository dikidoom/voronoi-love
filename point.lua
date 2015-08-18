local point = {}

local function mt_sub( pt1, pt2 )
  return point:new( pt1.x - pt2.x,
                    pt1.y - pt2.y )
end

local function mt_add( pt1, pt2 )
  return point:new( pt1.x + pt2.x,
                    pt1.y + pt2.y )
end

local point_mt = { __index = point,
                   __sub = mt_sub,
                   __add = mt_add }

function point:new( x, y )
  r = {
    x = x,
    y = y }
  setmetatable( r, point_mt )
  return r
end

return point
