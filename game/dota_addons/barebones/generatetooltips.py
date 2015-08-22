import os

prefix = "\"DOTA_Tooltip_Ability_"
directoryname = "hero_abilities"
filenames = os.listdir(directoryname)

special_values = ["Note", "Lore"]

abilities = []
ability = None

for fname in filenames:
	with open(os.path.join(directoryname, fname)) as infile:
		for line in infile:
			line = line.strip()
			if not line:
				continue

			if line[0] == '[':
				ability = {}
				truncated_line = line[len('[x] '):]
				ability['name'], rest_of_line = truncated_line.split(' (')
				ability['internal_name'], ability['desc'] = rest_of_line.split(") : ")

				ability['effects'] = []
				abilities.append(ability)
				continue
			
			if (not ability) or ("(" not in line) or ("(Scepter" in line):
				continue

			special = any((special_value in line) for special_value in special_values)

			print(line)
			effect, value = line.split(') :')
			name, key = effect.split(" (")
			# print(name)
			# print(key)
			key = key.replace(" ", "_")
			if not special:
				ability['effects'].append((name.upper() + ":", key.capitalize()))
			else:
				ability['effects'].append((value[1:], key.capitalize()))
	ability = None

with open('resource/tooltips/generated_tooltips.txt', mode='w', encoding='utf-8') as outfile:
	outfile.write("\n")
	for ability in abilities:
		name = ability['internal_name'].replace(" ", "_")
		outfile.write('\t\t{}{}" "{}"\n'.format(prefix, name, ability['name']))
		outfile.write('\t\t{}{}_Description" "{}"\n'.format(prefix, name, ability['desc']))
		for effect, key in ability['effects']:
			print(key)
			print(effect)
			outfile.write('\t\t{}{}_{}" "{}"\n'.format(prefix, name, key, effect))
		outfile.write("\n")