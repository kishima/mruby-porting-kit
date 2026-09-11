def f
  return 1
end
def g
  [1].each { |x| return x }
  nil
end
def h
  [1].each { |x| break x }
end
