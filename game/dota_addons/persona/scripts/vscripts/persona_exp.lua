BASE_EXP_REQUIRED = 300
EXP_REQUIRED_INCREASE_PER_LEVEL = 100

if PersonaExp == nil then
    print ( '[PersonaExp] creating PersonaExp' )
    PersonaExp = {}
    PersonaExp.__index = PersonaExp

    -- --this here is a dummy to check if the damage has already been parsed by our filter, it does nothing
    -- DamageSystem.handle = CreateItem('item_dummy_item', nil, nil):GetEntityIndex() 
    -- print('[DamageSystem] Dummy ability handle: ', DamageSystem.handle)
end

function PersonaExp:ExperienceFilter(event)
    print("EXP FILTER")
    for k,v in pairs(event) do
        print(k,v)
    end
    local experience = event.experience
    local hero = PlayerResource:GetSelectedHeroEntity(event.player_id_const)
    local activePersona = hero.activePersona
    activePersona.attributes["exp"] = activePersona.attributes["exp"] + experience
    local next_level_exp = (BASE_EXP_REQUIRED + EXP_REQUIRED_INCREASE_PER_LEVEL * activePersona.attributes["level"]) / 10
    if activePersona.attributes["exp"] >= next_level_exp then
        activePersona.attributes["exp"] = activePersona.attributes["exp"] - next_level_exp
        LevelUpPersona(hero, activePersona)
        print("persona leveled up")
    end
    print("current level:", activePersona.attributes["level"])
    print(activePersona.attributes["exp"], next_level_exp)
    return false
end

function LevelUpPersona(hero, personaItem)
    personaItem.attributes["level"] = personaItem.attributes["level"] + 1
    local level = personaItem.attributes["level"]
    print("leveling up to:", level)
    local learned_ability = personaItem.attributes["learned_abilities"][level]
    if learned_ability then
        print(learned_ability)
        table.insert(personaItem.attributes["abilities"], learned_ability)
    end
    hero:CastAbilityImmediately(personaItem, hero:GetPlayerID())
end