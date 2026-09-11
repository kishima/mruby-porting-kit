# ARYCAT / Array#concat で連結元と先が同じ配列のとき（4.1.0-rc）
a = [1, 2]
a.concat(a)
p a
e = []
e.concat(e)
p e
b = [1, 2]
def f(*x); x; end
p f(*b, *b)
c = [1, 2]
c = [*c, *c]
p c
