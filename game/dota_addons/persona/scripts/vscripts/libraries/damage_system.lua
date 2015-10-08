if DamageSystem == nil then
    print ( '[DamageSystem] creating DamageSystem' )
    DamageSystem = {}
    DamageSystem.__index = DamageSystem
    DamageSystem.kv_abilities = LoadKeyValues("scripts/npc/npc_custom_damage_abilities.txt")
    DamageSystem.kv_units     = LoadKeyValues("scripts/npc/npc_custom_damage_units.txt")

    --this here is a dummy to check if the damage has already been parsed by our filter, it does nothing
    DamageSystem.handle = CreateItem('item_dummy_item', nil, nil):GetEntityIndex() 
    print('[DamageSystem] Dummy ability handle: ', DamageSystem.handle)
end


function DamageSystem:DamageFilter( event )
    local attacker = EntIndexToHScript(event.entindex_attacker_const)
    local victim = EntIndexToHScript(event.entindex_victim_const)
    if not victim:IsBuilding() then
        local ability = attacker
        if event.entindex_inflictor_const then --if there is no inflictor key then it was an auto attack
            ability = EntIndexToHScript(event.entindex_inflictor_const)
        end
        -- print( '********damage event************' )
        -- for k, v in pairs(event) do
        --     print("DamageFilter: ",k, " ==> ", v)
        -- end

        if DamageSystem.handle == event.entindex_inflictor_const then --damage directly dealt with ApplyCustomDamage
           -- print('DamageFilter: Directly dealt from script')
           return true 
        end

        if not DamageSystem:CreateAbility(ability) then --this means we have no kv values for this ability
            -- print('DamageFilter: Couldnt find this ability')
            return true
        end
        
        -- print('DamageFilter: attack ability type:')
        -- print('>', ability:GetCustomDamageType(), '  - ', ability:GetCustomDamageModifier())
        -- print('DamageFilter: victim resistances:')
        -- for k,v in pairs(victim.resistances) do print('>', k,v) end
        -- local newdamage = event.damage * tonumber(ability:GetCustomDamageModifier())
        local newdamage = event.damage - event.damage / 100 * tonumber(victim:GetResistance("physical")) -- If damage was applied with autoattack, or applydamage instead of applycustomdamage, treat it as physical
        if newdamage <= 0 then
            -- print('DamageFilter: Damage is below 0, healing instead')
            victim:Heal(newdamage * -1, attacker)
            return false
        end
        -- print('DamageFilter: Dealing damage ', newdamage)
        event.damage = newdamage
        return true
    else
        return true
    end
end

function DamageSystem:CreateAbility(ability)
    --add the damage options to an ability
    if ability.custom_damage_type then
        return true
    end

    ability.custom_damage_type = ""
    ability.custom_damage_modifier = 1

    function ability:GetCustomDamageType()
        return ability.custom_damage_type
    end

    function ability:SetCustomDamageType(value)
        ability.custom_damage_type = value
    end   

    function ability:GetCustomDamageModifier()
        return ability.custom_damage_modifier
    end

    function ability:SetCustomDamageModifier(value)
        ability.custom_damage_modifier = value
    end      
    -- PrintTable(ability)
    return true
end

function DamageSystem:CreateResistances(npc)
    --add the resistance functions and values to a unit
    if npc.resistances ~= nil then
        return true
    end

    npc.resistances = {}
    npc.custom_damage_type = ""
    npc.custom_damage_modifier = 1

    function npc:AddResistance(resistance, value)
        npc.resistances[resistance] = npc.resistances[resistance] + value
    end

    function npc:SetResistance(resistance, value)
        npc.resistances[resistance] = value
    end

    function npc:GetResistance(resistance)
        return npc.resistances[resistance] or 0
    end

    function npc:GetCustomDamageType()
        return npc.custom_damage_type
    end

    function npc:SetCustomDamageType(value)
        npc.custom_damage_type = value
    end   

    function npc:GetCustomDamageModifier()
        return npc.custom_damage_modifier or 1
    end

    function npc:SetCustomDamageModifier(value)
        npc.custom_damage_modifier = value
    end      
    return true
end

function ApplyCustomDamage(victim, attacker, damage, damagetype, customdamagetype)
    --print('DamageFilter: victim resistances:')
    --for k,v in pairs(victim.resistances) do print(k,v) end
    --EntIndexToHScript(DamageSystem.handle)
    local newdamage = damage - damage / 100 *  tonumber(victim:GetResistance(customdamagetype))
    local damageTable = {
        victim = victim,
        attacker = attacker,
        damage = newdamage,
        damage_type = damagetype  ,
        ability = EntIndexToHScript(DamageSystem.handle)
    }
    -- print('[DamageSystem] Dealing ', customdamagetype, ' damage ', newdamage)
    ApplyDamage(damageTable)   
end

--add/substract resistance function to use with modifiers
function AddResistance(event)
    --for k, v in pairs(event) do
    --    print("AddResistance: ",k, " ==> ", v)
    --end
    local unit = event.target--= event.unit
    if unit.resistances then
        -- print('[DamageSystem] changing ', event.resistance, ' | ', unit:GetResistance(event.resistance), ' ==> ', unit:GetResistance(event.resistance) + event.value)
        unit:AddResistance(event.resistance, event.value)
    end
end