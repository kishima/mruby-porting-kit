class Base
  def f(a, b = 10, *r, k: 1, &blk)
    [a, b, r, k, blk ? blk.call : nil]
  end
end
class Sub < Base
  def f(a, b = 20, *r, k: 2, &blk)
    [1].map { super }
  end
end
p Sub.new.f(1)
p Sub.new.f(1, 2, 3, k: 4) { :blk }
class Sub2 < Base
  def f(a, b = 20, *r, k: 2)
    x = 0
    [1].each { [2].each { x = super } }
    x
  end
end
p Sub2.new.f(5, 6, 7, k: 8)
