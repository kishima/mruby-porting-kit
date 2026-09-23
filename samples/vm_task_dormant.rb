# 終わったタスクはDORMANTキューに残り、closeするまで回収されない
# （mruby-taskを含むホストビルドで実行。docs/notes/mruby-task.md）
before = GC.stat[:live]
200.times { 10.times { Task.new { nil } }; Task.run; GC.start }
p [Task.stat[:dormant][:count], GC.stat[:live] - before]   # => [2000, 6336]

before = GC.stat[:live]
ts = []
200.times { 10.times { ts << Task.new { nil } }; Task.run; ts.each(&:close); ts.clear; GC.start }
p [Task.stat[:dormant][:count], GC.stat[:live] - before]   # => [0, -62]
