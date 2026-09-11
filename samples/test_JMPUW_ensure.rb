def f
  while true
    begin
      break
    ensure
      puts "ensure"
    end
  end
end
