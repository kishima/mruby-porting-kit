def g
  x = 0
  [1].each { [2].each { x += 1 } }
  x
end
