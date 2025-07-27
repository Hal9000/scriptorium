f = open("file.txt", "r")
lines = f.readlines()
dict = {}

for line in lines:
  k, v = line.split()
  dict[k] = v
