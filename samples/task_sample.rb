# mruby-task のサンプル: 2 つのタスクと Task::Queue で受け渡す
q = Task::Queue.new

Task.new(name: "producer") do
  3.times do |i|
    puts "producer: push #{i}"
    q.push(i)
    sleep 0.1
  end
  q.close
end

Task.new(name: "consumer", priority: 200) do
  while (v = q.pop)      # 空なら WAITING になり、push で起こされる
    puts "consumer: got #{v} (tick=#{Task.tick})"
  end
  puts "consumer: queue closed"
end

Task.list.each { |t| puts "#{t.name}: #{t.status}" }
Task.run
puts "done: #{Task.list.map(&:status).uniq.inspect}"
