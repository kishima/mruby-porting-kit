# どの値が特異クラスを持てるか（mrb_singleton_class_ptr の分岐）
vals = {
  "Integer(1)"  => 1,
  "bigint"      => 2**70,
  "Float"       => 1.5,
  "Symbol"      => :a,
  "nil"         => nil,
  "true"        => true,
  "false"       => false,
  "String"      => "s",
  "frozen str"  => "s".freeze,
  "frozen obj"  => Object.new.freeze,
  "Rational"    => Rational(1, 2),
  "Class"       => String,
  "Module"      => Kernel,
}
vals.each do |label, v|
  begin
    sc = v.singleton_class
    puts "#{label}: #{sc.inspect} (frozen=#{sc.frozen?})"
  rescue => e
    puts "#{label}: #{e.class}: #{e.message}"
  end
end
begin
  o = Object.new.freeze
  def o.x; end
  puts "def on frozen: ok"
rescue => e
  puts "def on frozen: #{e.class}: #{e.message}"
end
class << nil
  def only_nil; :only_nil; end
end
p nil.only_nil, NilClass.instance_methods(false)
