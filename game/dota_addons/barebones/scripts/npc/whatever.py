import os

directoryname = "abilities"

filenames = os.listdir(directoryname)
with open('npc_abilities_custom.txt', 'w') as outfile:
	with open("abilities_start_template.txt") as infile:
		outfile.write(infile.read())
	for fname in filenames:
		with open(os.path.join(directoryname, fname)) as infile:
			outfile.write(infile.read())
	with open("abilities_end_template.txt") as infile:
		outfile.write(infile.read())