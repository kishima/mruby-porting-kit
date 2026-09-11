# issue #6439 の再現コード。ループ本体の先頭が begin で始まり、redo で本体の先頭へ戻る。
# 3.3.0 以前は ensure が実行されず 1 を出し続けた。3.4.0 以降は 1、2 を出して止まる
for _ in [1]
  begin
    puts 1
    redo
  ensure
    puts 2
    break
  end
end
