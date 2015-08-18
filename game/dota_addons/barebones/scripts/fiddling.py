import os

directoryname = "scripts/npc/abilities"

filenames = os.listdir(directoryname)
with open('scripts/npc/npc_abilities_custom.txt', 'w') as outfile:
	with open("scripts/npc/abilities_start_template.txt") as infile:
		outfile.write(infile.read())
	for fname in filenames:
		with open(os.path.join(directoryname, fname)) as infile:
			outfile.write(infile.read())
	with open("scripts/npc/abilities_end_template.txt") as infile:
		outfile.write(infile.read())

directoryname = "scripts/plaintextlocalisation"
filenames = os.listdir(directoryname)

for fname in filenames:
	plaintextFile=open(os.path.join(directoryname, fname)),'r')

	row = plaintextFile.readlines()

	for line in row:
	    if line.find("Example") > -1:
	        info = line.split()
	        var1 = info[0]
	        var2 = info[1]
	        var3 = info[2]
	        remaining_data = ????