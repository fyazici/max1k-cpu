fname = r"dbus.csv"

with open(fname) as f:
    lines = f.readlines()

stdout = ""

for l in lines:
    vals = l.split(",")
    if len(vals) > 2 and vals[1] == "W" and vals[2] == "A=A0010008":
        stdout += chr(int(vals[3][8:10], 16))

print(stdout)
