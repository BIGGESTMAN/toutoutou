require "personas"

GOLD_FOR_PERSONA_DROP = 700

if PersonaDrops == nil then
	print ( '[PersonaDrops] creating PersonaDrops' )
	PersonaDrops = {}
	PersonaDrops.__index = PersonaDrops
end

function PersonaDrops:GoldFilter(event)
	local DEBUG = true
	if DEBUG then
		print("GOLD FILTER")
		for k,v in pairs(event) do
			print(k,v)
		end
	end

	local playerID = event.player_id_const
	local hero = PlayerResource:GetSelectedHeroEntity(playerID)
	local playerGold = PlayerResource:GetGold(playerID)
	if DEBUG then print("Current gold: "..playerGold) end

	if playerGold >= GOLD_FOR_PERSONA_DROP and hero:HasAnyAvailableInventorySpace() then
		PlayerResource:SpendGold(playerID, GOLD_FOR_PERSONA_DROP, 0)
		DropPersona(hero)
	end
	return true
end

function DropPersona(hero)
	-- print("Dropping new persona")
	local highestCurrentLevel = 0
	for i=0,5 do
		local persona = hero:GetItemInSlot(i)
		if persona and persona.attributes and persona.attributes["level"] > highestCurrentLevel then
			highestCurrentLevel = persona.attributes["level"]
		end
	end

	local possiblePersonas = {}
	for k,persona in pairs(personas_table) do
		if persona["level"] <= highestCurrentLevel then
			table.insert(possiblePersonas, persona)
		end
	end

	local personaType = possiblePersonas[RandomInt(1, #possiblePersonas)]
	local personaItem = CreateItem("item_"..personaType["name"], hero, hero)
	hero:AddItem(personaItem)
	personaItem = InitializePersona(personaItem)

	GameRules:SendCustomMessage("New Persona: "..personaType["name"], hero:GetTeamNumber(), hero:GetPlayerID())
end