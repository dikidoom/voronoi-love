local matrix = require( 'matrix' )
local point = require( 'point' )
local vector = point -- use to increase clarity of intent

--------------------------------------------------------------------------------
colors = {
  black = { 0, 0, 0 },
  dark = { 20, 20, 20 },
  shady = { 40, 40, 40 },
  light = { 129, 128, 128 },
  white = { 255, 255, 255 },
  yellow = { 205, 180, 121 },
  red = { 156, 95, 80 },
  blue = { 99, 167, 194 }}

--------------------------------------------------------------------------------
local keep_pt = point:new( 100, 200 )
local cut_pt = point:new( 400, 230 )
-- local middle_pt = point:new( 0, 0 )

local square = {
  point:new(-1, -1),
  point:new(-1, 1),
  point:new(1, 1),
  point:new(1, -1)
}

local square2 = {
  point:new( 10, 10 ),
  point:new( 590, 10 ),
  point:new( 590, 590 ),
  point:new( 10, 590 )}

local function scalePoly( poly, scale )
   result = {}
   for i, pt in ipairs( poly ) do
     table.insert( result,
                   point:new( pt.x * scale,
                              pt.y * scale ))
   end
   return result
end

local function poly_pairs( p )
  -- iterator making pt1,pt2-pairs from {pt,...}
  local i = 1
  return function()
    local pt1 = p[i]
    local pt2 = p[i+1]
    if pt2 == undefined then pt2 = p[1] end
    i = i + 1
    if i > #p+1 then return nil else return pt1, pt2 end
  end
end

local function drawPoly( poly )
  for pt1, pt2 in poly_pairs( poly ) do
    love.graphics.line( pt1.x, pt1.y,
                        pt2.x, pt2.y )
  end
end

local function drawPoint( pt )
  love.graphics.circle( 'fill', pt.x, pt.y, 5 )
end

local function drawVector( origin, vec )
  love.graphics.line( origin.x, origin.y,
                      origin.x + vec.x,
                      origin.y + vec.y )
end

--------------------------------------------------------------------------------
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
  local angle = math.atan( angle_hint.y, angle_hint.x ) * -1
  local i_keep, i_dist = 0, 2^32 -- TODO MAGIC NUMBER
  for i = 1, #poly do
    local pt = matrix.rotate2d( poly[i], angle )
    if pt.x < i_dist then
      i_dist = pt.x
      i_keep = i
    end
  end
  -- create new poly by shifting remote point to first place
  local poly_shift = {}
  -- NB: Löve uses Lua 5.1
  -- table.move( poly, i_keep, #poly, 1, poly_shift )
  -- table.move( poly, 1, i_keep-1, #poly_shift+1, poly_shift )
  for i = i_keep, #poly do table.insert( poly_shift, poly[ i ]) end
  for i = 1, i_keep-1   do table.insert( poly_shift, poly[ i ]) end
  
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

--------------------------------------------------------------------------------
love.load = function()
  love.window.setMode( 600, 600 )
  love.window.setTitle( 'cut convex' )
end

love.draw = function()
  love.graphics.setBackgroundColor( 92, 92, 92 )
  -- love.graphics.setColor( colors.dark )
  -- drawPoly( square2 )
  love.graphics.setColor( colors.red )
  drawPoint( keep_pt )
  love.graphics.setColor( colors.blue )
  drawPoint( cut_pt )
  --                 --
  -- THE CALCULATION --
  --                 --
  -- find midpoint and orthogonal (cutting) vector between 2 points
  local middle_pt, cut_vec = middle( keep_pt, cut_pt )
  love.graphics.setColor( colors.yellow )
  drawPoint( middle_pt )
  drawVector( middle_pt, cut_vec )
  -- check if cut_vec intersects any lines
  love.graphics.setColor( colors.light )
  for pt1, pt2 in poly_pairs( square2 ) do
    local hit, hit_pt = intersect( pt1, pt2, middle_pt, cut_vec )
    if hit then
      drawPoint( hit_pt )
    end
  end

  local poly_cut, i_keep = cut( square2, keep_pt, cut_pt )
  love.graphics.setColor( colors.light )
  drawPoly( poly_cut )
  love.graphics.setColor( colors.black )
  drawPoint( i_keep )

end

local mouse_bindings = {
  ['l'] = function( x, y )
    keep_pt = point:new( x, y )
  end,
  ['r'] = function( x, y )
    cut_pt = point:new( x, y )
  end
}

local mouse_down = ''

love.mousepressed = function( x, y, button )
  mouse_down = button
  local fn = mouse_bindings[ button ]
  if type( fn ) == 'function' then
    fn( x, y )
  end
end

love.mousemoved = function( x, y, dx, dy )
  if mouse_down == '' then return end
  local fn = mouse_bindings[ mouse_down ]
  if type( fn ) == 'function' then
    fn( x, y )
  end
end

love.mousereleased = function( x, y, button )
  mouse_down = ''
end
