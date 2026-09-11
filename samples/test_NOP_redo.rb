def f(x)
  while x < 3
    x += 1
    redo if x == 1
  end
end
