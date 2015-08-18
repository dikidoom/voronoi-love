require( 'util' )
local console = require( 'console' )
local colors = require( 'colors' )

local point = require( 'point' )
local vector = point -- use to increase clarity of intent
local cut = require( 'cut' )

--------------------------------------------------------------------------------
local dots = {}

for i = 1, 12 do
  local dot = {}
  table.insert( dot, point:new(( love.math.random() * 580 ) + 20,
                               ( love.math.random() * 580 ) + 20 ))
  table.insert( dot, point:new(( love.math.random() * 100 ) - 50,
                  ( love.math.random() * 100 )- 50 ))
  table.insert( dots, dot )
end

local square = {
  point:new( 10, 10 ),
  point:new( 590, 10 ),
  point:new( 590, 590 ),
  point:new( 10, 590 )
}

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
love.update = function( dt )
  for _, dot in pairs( dots ) do
    local velo = dot[2] * dt
    dot[1] = dot[1] + velo
    if     dot[1].x < 10  then dot[2].x = dot[2].x * -1
    elseif dot[1].x > 590 then dot[2].x = dot[2].x * -1 end
    if     dot[1].y < 10  then dot[2].y = dot[2].y * -1
    elseif dot[1].y > 590 then dot[2].y = dot[2].y * -1 end
    -- if     dot[1].x <= 10  then dot[1].x = dot[1].x + 580
    -- elseif dot[1].x >= 590 then dot[1].x = dot[1].x - 580 end
    -- if     dot[1].y <= 10  then dot[1].y = dot[1].y + 580
    -- elseif dot[1].y >= 590 then dot[1].y = dot[1].y - 580 end
  end
end

love.draw = function()
  love.graphics.setBackgroundColor( 92, 92, 92 )

  for i, dot in ipairs( dots ) do
    love.graphics.setColor( colors.red )
    love.graphics.circle( 'fill', dot[1].x, dot[1].y, 5 )
    local shape = square
    for i2, other_dot in ipairs( dots ) do
      if not( i == i2 )then shape = cut.cut( shape, dot[1], other_dot[1] ) end
    end
    love.graphics.setColor( colors.dark )
    drawPoly( shape )
  end

  love.graphics.setColor( colors.yellow )
  drawPoly( square )

end

local key_bindings = {
}

local mouse_bindings = {
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
