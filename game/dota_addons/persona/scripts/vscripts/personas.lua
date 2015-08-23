-- str = damage, mag = intelligence, end = strength, swft = movespeed, agi = range
-- resists: physical, fire, ice, wind, thunder, light, dark
-- resist values: 0 = normal, -1 = weak, 1 = resist, 2 = block, 3 = absorb

CHARIOT = 3

personas_table = {
	slime = {
		arcana = CHARIOT,
		str = 3,
		mag = 2,
		endr = 3,
		swft = 5,
		agi = 0,
		abilities = {"bash", "tarunda", "resist_physical"},
		level = 2,
		resists = {1,-1,0,0,0,0,0}
	}
}

function Activate(keys)
	local caster = keys.caster
	local ability = keys.ability
end

function InitializePersonaStats(keys)
	local caster = keys.caster
	local ability = keys.ability
	-- print("INITIALIZING")
	-- for k,v in pairs(keys) do
	-- 	print(k,v)
	-- end
end

function InitializePersona(keys)
	-- for k,v in pairs(keys) do
	-- 	print(k,v)
	-- end

	local personaName = string.gsub(keys.itemname, "item_", "")
	print(personaName)

	local hero = PlayerResource:GetSelectedHeroEntity(keys.PlayerID)
	print(hero)

	-- local entities = Entities:FindAllByClassname("slime")
	-- print(entities, #entities)
	local items = {}
	for i=0,5 do
		items[i + 1] = hero:GetItemInSlot(i)
	end
	for _,item in pairs(items) do
		print(item:GetAbilityName())
		-- for k,v in pairs(item) do
		-- 	print(k,v)
		-- end
	end
end