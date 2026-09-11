def f(obj, blk)
  obj.size
  obj.push(1, 2)
  obj.each { |x| x }
  obj.each(&blk)
  p obj
end
