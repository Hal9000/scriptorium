def mymeth
  @foo = "bar"
  def @foo.some_meth
    puts "Here we go!"
  end
  @foo
end

x = mymeth

x.some_meth
