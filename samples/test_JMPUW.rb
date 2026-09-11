def f
  i = 0
  while i < 5
    i += 1
    next if i == 2
    break if i == 4
  end
  i
end
