import os

directoryname = "tooltips"

filenames = os.listdir(directoryname)
with open('addon_english.txt', 'w') as outfile:
	with open("tooltips_start_template.txt") as infile:
		outfile.write(infile.read())
	for fname in filenames:
		with open(os.path.join(directoryname, fname)) as infile:
			outfile.write(infile.read())
	with open("tooltips_end_template.txt") as infile:
		outfile.write(infile.read())