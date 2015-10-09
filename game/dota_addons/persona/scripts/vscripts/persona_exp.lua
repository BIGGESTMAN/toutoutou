require "personas"

BASE_EXP_REQUIRED = 300
EXP_REQUIRED_INCREASE_PER_LEVEL = 100

STAT_INCREASE_PERCENT = 20

if PersonaExp == nil then
	print ( '[PersonaExp] creating PersonaExp' )
	PersonaExp = {}
	PersonaExp.__index = PersonaExp
end

function PersonaExp:ExperienceFilter(event)
	local DEBUG = false
	if DEBUG then
		print("EXP FILTER")
		for k,v in pairs(event) do
			print(k,v)
		end
	end
	local experience = event.experience
	local hero = PlayerResource:GetSelectedHeroEntity(event.player_id_const)
	local activePersona = hero.activePersona
	activePersona.attributes["exp"] = activePersona.attributes["exp"] + experience
	local next_level_exp = (BASE_EXP_REQUIRED + EXP_REQUIRED_INCREASE_PER_LEVEL * activePersona.attributes["level"]) / 10
	if activePersona.attributes["exp"] >= next_level_exp then
		activePersona.attributes["exp"] = activePersona.attributes["exp"] - next_level_exp
		LevelUpPersona(hero, activePersona)
		if DEBUG then print("persona leveled up") end
	end
	if DEBUG then
		print("current level:", activePersona.attributes["level"])
		print(activePersona.attributes["exp"], next_level_exp)
	end
	return false
end

function LevelUpPersona(hero, personaItem)
	local DEBUG = false
	personaItem.attributes["level"] = personaItem.attributes["level"] + 1
	local level = personaItem.attributes["level"]
	if DEBUG then print("leveling up to:", level) end

	-- Check for learn ability
	local learned_ability = personaItem.attributes["learned_abilities"][level]
	if learned_ability then
		if DEBUG then print(learned_ability) end
		table.insert(personaItem.attributes["abilities"], learned_ability)
	end

	local personaAttributes = personaItem.attributes
	local personaName = personaAttributes["name"]

	-- Increase stats
	local oldStr = math.floor(personaAttributes["str"])
	local oldEndr = math.floor(personaAttributes["endr"])
	local oldMag = math.floor(personaAttributes["mag"])

	if DEBUG then print(personaAttributes["str"]) end
	personaAttributes["str"] = personaAttributes["str"] + personas_table[personaName]["str"] * STAT_INCREASE_PERCENT / 100
	if DEBUG then print(personaAttributes["str"]) end
	personaAttributes["mag"] = personaAttributes["mag"] + personas_table[personaName]["mag"] * STAT_INCREASE_PERCENT / 100
	personaAttributes["endr"] = personaAttributes["endr"] + personas_table[personaName]["endr"] * STAT_INCREASE_PERCENT / 100

	local strIncrease = math.floor(personaAttributes["str"]) - oldStr
	local endrIncrease = math.floor(personaAttributes["endr"]) - oldEndr
	local magIncrease = math.floor(personaAttributes["mag"]) - oldMag
	-- GameRules:SendCustomMessage(personaItem.attributes["name"].." leveled up! +"..strIncrease.." STR, +"..endrIncrease.." ENDR, +"..magIncrease.." MAG", hero:GetTeamNumber(), hero:GetPlayerID())
	if strIncrease == 0 then strIncrease = 10 end
	if endrIncrease == 0 then endrIncrease = 10 end
	if magIncrease == 0 then magIncrease = 10 end
	local statsIncreaseParticle = ParticleManager:CreateParticle("particles/general/levelup_stats.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero)
	ParticleManager:SetParticleControl(statsIncreaseParticle, 17, Vector(0,strIncrease,0))
	ParticleManager:SetParticleControl(statsIncreaseParticle, 19, Vector(0,endrIncrease,0))
	ParticleManager:SetParticleControl(statsIncreaseParticle, 21, Vector(0,magIncrease,0))

	hero:CastAbilityImmediately(personaItem, hero:GetPlayerID())
	personaItem:EndCooldown()
end