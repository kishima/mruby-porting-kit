def f(a, &nil)
  a
end
p f(1)
begin
  f(1) { }
rescue ArgumentError => e
  p e.message
end
