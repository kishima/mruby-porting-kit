# LOADI_0 はピープホール最適化で特別扱いされる: a[0] は GETIDX0、a[1] は LOADI_1 + GETIDX
def f(a)
  a[0]
end
def g(a)
  a[1]
end
