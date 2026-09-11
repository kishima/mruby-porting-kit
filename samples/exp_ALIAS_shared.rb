# alias が元のメソッド実体を共有するのか、名前で引き直すのか
class A
  def f; :old; end
  alias g f
  def f; :new; end
end
p [A.new.f, A.new.g]        # g は alias 時点の実体を指す

class B
  def h; __method__; end
  alias i h
end
p B.new.i                   # alias 経由でも __method__ は元の名前

class C
  def m; :m; end
  alias n m
  alias o n                 # alias の alias
  private :m
end
p [C.new.o, C.private_instance_methods(false), C.public_instance_methods(false).sort]

class Array
  alias sz size             # C 関数のメソッド
end
p [1, 2].sz
class Array
  def size; 99; end
end
p [[1, 2].sz, [1, 2].size]  # C 関数も alias 時点の実体

class D
  def base; :base; end
end
class E < D
  def base; super; end
  alias b2 base
end
p E.new.b2                  # alias 経由の super は元の名前で探索する
