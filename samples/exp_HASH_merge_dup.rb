# HASHCAT（mrb_hash_merge）で同じキーがあるとき（4.1.0-rc）
h = {a: 1, b: 2}
p({**h, a: 3})    # HASH 0, HASHCAT, HASHADD → 後の a: 3 が勝つ
p({a: 3, **h})    # HASH 1, HASHCAT → h の a: 1 が勝つ
p({a: 3, **h}.keys)  # 上書きされても順序は最初の位置のまま
p h               # h は変わらない
