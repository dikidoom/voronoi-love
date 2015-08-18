require( 'util' )
local console = require( 'console' )
local colors = require( 'colors' )

local point = require( 'point' )
local vector = point -- use to increase clarity of intent
local cut = require( 'cut' )

--------------------------------------------------------------------------------
local keep_pt = point:new( 100, 200 )
local cut_pt = point:new( 400, 230 )

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

local shape = square2

local function scalePoly( poly, scale )
   result = {}
   for i, pt in ipairs( poly ) do
     table.insert( result,
                   point:new( pt.x * scale,
                              pt.y * scale ))
   end
   return result
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
love.draw = function()
  love.graphics.setBackgroundColor( 92, 92, 92 )

  love.graphics.setColor( colors.light )
  drawPoly( shape )

  love.graphics.setColor( colors.red )
  drawPoint( keep_pt )
  love.graphics.setColor( colors.blue )
  drawPoint( cut_pt )

  local poly_cut, i_keep = cut.cut( shape, keep_pt, cut_pt )
  love.graphics.setColor( colors.dark )
  drawPoly( poly_cut )
  love.graphics.setColor( colors.black )
  drawPoint( i_keep )

  local middle_pt, cut_vec = cut.middle( keep_pt, cut_pt )
  love.graphics.setColor( colors.yellow )
  drawPoint( middle_pt )
  drawVector( middle_pt, cut_vec )

  --console.draw()
end

local key_bindings = {
  ['tab'] = function()
    shape = cut.cut( shape, keep_pt, cut_pt )
  end
}

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

love.keypressed = function( key )
  local fn = key_bindings[ key ]
  if type( fn ) == 'function' then
    fn()
  end
end
