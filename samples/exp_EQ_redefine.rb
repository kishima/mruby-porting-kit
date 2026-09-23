# Integer#< を再定義しても LT 命令は影響を受けないことの確認（4.1.0-rc2）
class Integer
  def <(o); :redefined; end
  def ==(o); :redefined_eq; end
end
p 1 < 2          # LT 命令 → 整数同士は VM が直接比較
p 1.<(2)         # 明示的なメソッド呼び出し → SEND → 再定義が効く
p 1 == 1         # EQ 命令
p 1.==(1)
p 1 < 2.5        # Integer/Float も VM 内で比較
