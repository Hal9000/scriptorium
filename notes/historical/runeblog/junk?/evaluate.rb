lines = File.readlines("todo.txt")

list = []
lines.each do |line|
  line.chomp!
  tag = line[0]
  break if tag == "x"
  next if tag.nil?
  imp, hard = line[2].to_i, line[4].to_i
  text = line[8..-1]
# p [imp, hard, text]
  score = imp*imp/hard.to_f # imp**2 / (hard**2).to_f
  list << [imp, hard, score, text]
end

list = list.sort_by {|x| -x[2] }

list.each {|x| printf "%d %d %5.2f  %s\n", x[0], x[1], x[2], x[3] }
