-- NB: uses global namespace

function poly_pairs( p )
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
