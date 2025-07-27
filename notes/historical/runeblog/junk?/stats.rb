lines = File.readlines("statics")

lines = lines.map(&:chomp).reject {|x| x == " " || x.empty? }
lines = lines.map(&:strip)

hash = {}
key = nil

lines.each do |line|
  if line.start_with?("---")
    key = line.split.last
    hash[key] = []
  else 
    hash[key] << line
  end
end

files = hash.keys

hash.each_pair do |file, refs|
  others = files - [file]
  others.each do |other|
    puts "\nFile: #{other}"
    refs.each do |ref|
      front = "---- " + (ref + " ").ljust(20, "-")
      body = `ack #{ref} #{other}`
      next if body.empty?
      puts front
      puts body
      puts
    end
  end
end
