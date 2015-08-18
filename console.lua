local console = {}
console.queue = {}
console.queueLength = 12
console.color = { 128, 128, 128 }

console.log = function( entry )
  table.insert( console.queue, entry )
  if #console.queue > console.queueLength then table.remove( console.queue, 1 ) end
end

console.draw = function()
  love.graphics.setColor( console.color )
  for i,v in ipairs( console.queue ) do
    love.graphics.print( v,
                         10,
                         (#console.queue-i)*20)  
  end
end

console.log( "console launched @" .. os.time())
console.id = os.time()

return console