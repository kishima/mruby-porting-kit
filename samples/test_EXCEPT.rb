def f
  begin
    raise "boom"
  rescue RuntimeError => e
    e.message
  ensure
    puts "done"
  end
end
