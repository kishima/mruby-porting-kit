# Enumerator を使う書き方と、使わずに済ませる書き方（どちらが Fiber を作るか）
class Fiber
  class << self
    alias orig_new new
    def new(&b); $used = true; orig_new(&b); end
  end
end

def probe(name)
  $used = false
  v = yield
  puts "#{name}: fiber=#{$used} -> #{v.inspect}"
end

probe("4.times.map")         { 4.times.map { |i| i * i } }
probe("Array.new(4)")        { Array.new(4) { |i| i * i } }
probe("each_with_index.map") { [10,20].each_with_index.map { |v,i| [i,v] } }
probe("map.with_index")      { [10,20].map.with_index { |v,i| [i,v] } }
probe("each_cons(2).to_a")   { [1,2,3].each_cons(2).to_a }
probe("lazy(無限列)") do
  (1..Float::INFINITY).lazy.select { |x| x % 7 == 0 }.first(3)
end
probe("zip")                 { [1,2].zip([3,4]) }
probe("zip を手で組む") do
  b = [3,4]
  [1,2].each_with_index.map { |v,i| [v, b[i]] }
end
