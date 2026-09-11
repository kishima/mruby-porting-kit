class Base
  def f(a, k: 1, **o)
    [a, k, o]
  end
end
class Sub < Base
  def f(a, k: 2, **o)
    super
  end
end
p Sub.new.f(1, k: 4, z: 9)
p Sub.new.f(1)
