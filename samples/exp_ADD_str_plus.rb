# ADD の String 同士は新しい文字列を返し、元を変えない（4.1.0-rc2）
s = "ab"
t = s + "cd"
p s, t, s.equal?(t)
u = s + ""
p u, s.equal?(u)
