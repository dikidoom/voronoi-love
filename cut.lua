local point = require( 'point' )
local matrix = require( 'matrix' )

local function middle( pt1, pt2 )
  local mid_pt = point:new(
    ( pt1.x + pt2.x ) / 2,
    ( pt1.y + pt2.y ) / 2 )
  local mid_vec = point:new(
    pt1.y - pt2.y,
    ( pt1.x - pt2.x ) * -1 ) -- x and y intentionally swapped
  return mid_pt, mid_vec
end

local function intersect( pt1, pt2, -- the line
                          origin, -- point
                          vector -- vector
                        )
  -- checks if vector intersects the given piece of line (in either direction)
  -- return true/false accordingly and the intersection point (might not lie on line)

  -- get line angle
  local angle = math.atan2( pt2.y - pt1.y,
                            pt2.x - pt1.x )
  -- transform line, vector and origin into line space
  -- translations
  local o = origin - pt1
  local p1 = point:new( 0, 0 )
  local p2 = pt2 - pt1
  local v -- not translated
  -- rotations
  p2 = matrix.rotate2d( p2, angle * -1 )
  o = matrix.rotate2d( o, angle * -1 )
  v = matrix.rotate2d( vector, angle * -1 )
  -- delta-y is the y-distance of line to origin
  local delta_y = o.y
  -- multiplier is delta-y divided by vector.y
  local multi = delta_y / v.y
  -- ( if vector.y is pointing away, invert vector.x later )
  -- run-x is vector.x multiplied by multiplier
  local run_x = v.x * multi
  -- hit-x is origin.x added to run.x
  -- NB: subtract X here instead of inverting vector.y anywhere above
  local hit_x = o.x - run_x
  -- if hit_x is within line limits return true, else return false
  -- NB: line[1].x is always 0
  local hit = hit_x >= 0 and hit_x <= p2.x
  local hit_point = matrix.rotate2d( point:new( hit_x, 0 ), angle ) + pt1
  --return hit, line, origin, vector, hit_x
  return hit, hit_point
end

local function cut( poly,
                    in_pt, -- supposed to be IN new poly
                    out_pt -- supposedly OUT of new poly
                  )
  -- return cut poly

  -- find most remote point from cut
  local angle_hint = out_pt - in_pt
  local angle = math.atan2( angle_hint.y, angle_hint.x ) * -1
  --console.log( angle_hint.x .. " " .. angle_hint.y .. " " .. angle )
  local i_keep, i_dist = 0, 2^32 -- TODO MAGIC NUMBER
  for i = 1, #poly do
    local pt = matrix.rotate2d( poly[i] - in_pt, angle )
    if pt.x < i_dist then
      i_dist = pt.x
      i_keep = i
    end
  end
  -- create new poly by shifting remote point to first place
  local poly_shift = {}
  -- NB: Löve 9.2 uses Lua 5.1, so there is no table.move yet :,(
  for i = i_keep, #poly do table.insert( poly_shift, poly[ i ]) end -- table.move( poly, i_keep, #poly, 1, poly_shift )
  for i = 1, i_keep-1   do table.insert( poly_shift, poly[ i ]) end -- table.move( poly, 1, i_keep-1, #poly_shift+1, poly_shift )
  -- get cut vector
  local cut_pt, cut_vec = middle( in_pt, out_pt )
  -- find all intersections and pair them up
  local poly_cut = {}
  local i = 1
  local hit_flip = false -- hit-flip toggles on every hit and determines which points make it into the new poly
                         -- (entry- and exit-points of our cutting-vector are marked by this)
  for pt1, pt2 in poly_pairs( poly_shift ) do
    local hit, hit_pt = intersect( pt1, pt2, cut_pt, cut_vec )
    if hit then
      if not hit_flip then
        table.insert( poly_cut, pt1 )
        table.insert( poly_cut, hit_pt )
      else
        table.insert( poly_cut, hit_pt )
      end
      hit_flip = not hit_flip
    else
      if not hit_flip then table.insert( poly_cut, pt1 ) end
    end
    i = i + 1
  end
  return poly_cut, poly[ i_keep ]
end

return { cut = cut,
         middle = middle }
