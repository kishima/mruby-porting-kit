# undef で呼ばれるフック
class A
  def self.method_undefined(name)
    puts "method_undefined #{name.inspect}"
  end
  def self.method_added(name)
    puts "method_added #{name.inspect}"
  end
  def f; end
  undef f
end
o = Object.new
def o.x; end
def o.singleton_method_undefined(name)
  puts "singleton_method_undefined #{name.inspect}"
end
class << o
  undef x
end
p o.respond_to?(:x)
