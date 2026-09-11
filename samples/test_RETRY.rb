def f
  n = 0
  begin
    n += 1
    raise "x" if n < 3
  rescue
    retry
  end
  n
end
