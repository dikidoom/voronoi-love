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
     table.insert( result, point:new( pt.x * scale,
                                      pt.y * scale ))
     --print( pt.x * scale, pt.y * scale )
   end
   return result
end

local function drawPoly( poly )
  for i = 0, #poly-1 do
    local pt1 = poly[i]
    if pt1 == undefined then pt1 = poly[#poly] end
    local pt2 = poly[i+1]
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

local function intersect( line, -- { point, point }
                          origin, -- point
                          vector -- vector
                        )
  -- checks if vector intersects the given piece of line (in either direction)
  -- return true/false accordingly and the intersection point (might not lie on line)

  -- get line angle
  local angle = math.atan2( line[2].y - line[1].y,
                            line[2].x - line[1].x )
  -- transform line, vector and origin into line space
  -- translations
  local o = origin - line[1]
  local l = { point:new( 0, 0 ),
              line[2] - line[1] }
  local v -- not translated
  -- rotations
  l = { l[1],
        matrix.rotate2d( l[2], angle * -1 )}
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
  local hit = hit_x >= 0 and hit_x <= l[2].x
  local hit_point = matrix.rotate2d( point:new( hit_x, 0 ), angle ) + line[1]
  --return hit, line, origin, vector, hit_x
  return hit, hit_point
end

--------------------------------------------------------------------------------
love.load = function()
  love.window.setMode( 600, 600 )
  love.window.setTitle( 'cut convex' )
end

love.draw = function()
  love.graphics.setBackgroundColor( 92, 92, 92 )
  love.graphics.setColor( colors.dark )
  drawPoly( square2 )
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
  -- debug: line transformation
  local line = { point:new( 100, 100 ),
                 point:new( 400, 190 ) }
                 -- point:new( love.mouse.getX(),
                 --            love.mouse.getY())}
  --local hit, line2, origin2, vector2, hit_x = intersect( line, middle_pt, cut_vec )
  local hit, hit_point = intersect( line, middle_pt, cut_vec )
  love.graphics.setColor( colors.dark )
  drawPoly( line )
  if hit then
    love.graphics.setColor( colors.white )
  else
    love.graphics.setColor( colors.light )
  end
  drawPoint( hit_point )
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
