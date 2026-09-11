class Base
  def f(a, k: 1)
    [a, k]
  end
  def g(a, &blk)
    [a, blk ? blk.call : :noblk]
  end
end
class Sub < Base
  def f(a, k: 2)
    super
  end
  def g(a, &blk)
    super(a + 1)
  end
end
p Sub.new.f(1, k: 4)
p Sub.new.g(1) { :given }
p Sub.new.g(1)
class Sub3 < Base
  def g(a)
    [1].map { super(a + 2) }
  end
end
p Sub3.new.g(1) { :outer }
