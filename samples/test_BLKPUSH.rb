def f(a)
  yield a
end
def g(a, &blk)
  blk.call(a)
end
