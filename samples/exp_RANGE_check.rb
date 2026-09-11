# RANGE_INC / RANGE_EXC の値の検査（4.1.0-rc）
class C
  attr_reader :v
  def initialize(v); @v = v; end
  def <=>(o); $cmp += 1; v <=> o.v; end
end
$cmp = 0
r = (C.new(1)..C.new(3))
p r.class, $cmp                 # <=> が呼ばれた回数
class N; end
begin; N.new..N.new; rescue ArgumentError => e; p e; end   # <=> が nil → エラー
begin; 1.."a"; rescue ArgumentError => e; p e; end
p((1..nil).class, (nil..1).class, (nil..nil).class)     # nil は許される
p ("a".."c").to_a
begin; (1..2.5).class; rescue => e; p e; end
$cmp = 0
(1..3)
p $cmp                          # Integer 同士は <=> を呼ばない
