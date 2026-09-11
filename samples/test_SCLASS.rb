class Foo
  def bar
  end
  def baz
  end
  class << self
    def cm
    end
  end
  alias bar2 bar
  undef baz
end
