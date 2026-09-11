# HASH / HASHADD（mrb_hash_set）がユーザ定義の hash と eql? を使うか（4.1.0-rc）
class K
  attr_reader :n
  def initialize(n); @n = n; end
  def hash; $hash_calls += 1; n; end
  def eql?(o); $eql_calls += 1; o.is_a?(K) && o.n == n; end
end
$hash_calls = 0; $eql_calls = 0
h = {K.new(1) => :a, K.new(1) => :b, K.new(2) => :c}
p h.size, $hash_calls, $eql_calls      # 16 組以下は線形探索。eql? は呼ぶが hash は呼ばない
class S
  def hash; 1; end       # eql? は定義しない（既定は同一性）
end
p({S.new => 1, S.new => 2}.size)
# 17 組目でハッシュ表に切り替わり、hash が呼ばれるようになる
$hash_calls = 0; $eql_calls = 0
big = {}
20.times { |i| big[K.new(i)] = i }
p big.size, $hash_calls > 0
