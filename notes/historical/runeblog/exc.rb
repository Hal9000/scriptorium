class MyException < StandardError

  def initialize(file, dir)
    msg = "Could not find #{file} under #{dir}"
    super(msg)
  end

end

raise MyException.new("stuff.txt", "/home/willard")
