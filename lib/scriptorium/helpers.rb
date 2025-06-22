
module Scriptorium::Helpers
  def getvars(file)
    lines = File.readlines(file)
    lines.map! {|line| line.sub(/ #.*$/, "").strip }
    # FIXME - what if variable value has a # in it?
    vhash = Hash.new("")
    lines.each do |line|
      var, val = line.split(" ", 2)
      vhash[var] = val
    end
    vhash
  end
end
