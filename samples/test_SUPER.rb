class Upper
  def f(a, b)
    a + b
  end
end
class Lower < Upper
  def f(a, b)
    super
  end
  def g(a, b)
    super(b, a)
  end
end
