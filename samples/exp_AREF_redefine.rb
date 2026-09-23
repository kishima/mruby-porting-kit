# Array#[] / []= の再定義で GETIDX/SETIDX がメソッド呼び出しに切り替わる（4.1.0-rc2）
# 注: Kernel#p は内部で args[i] を使うので、Array#[] を再定義すると p 自体が壊れる。
#     そのため出力には $stdout.write を使い、配列の inspect も避ける
def show(x); $stdout.write "#{x.inspect}\n"; end
a = [10, 20]
h = {k: 1}
s = "xyz"
show a[0]; show a[1]; show h[:k]; show s[0]
class Array
  alias_method :orig_aref, :[]
  def [](i); :ary_aref; end
  def []=(i, v); :ary_aset; end
end
show a[0]; show a[1]   # 同じバイトコード（GETIDX0 / GETIDX）が再定義後はメソッド呼び出しになる
a[0] = 99
show a.first           # []= も切り替わる（要素は変わらない）
show h[:k]; show s[0]  # Hash / String は影響を受けない
class Hash
  def [](k); :hash_aref; end
end
show h[:k]
class Array
  alias_method :[], :orig_aref   # 組み込みの実体に戻すと再び命令が答える
end
show a[0]
class Array
  alias_method :[], :fetch       # 別の C 関数に差し替えた場合は戻らない
end
begin
  show a[5]                      # 命令が答えるなら nil、fetch なら IndexError
rescue IndexError => e
  show e
end
