function unitKilled(keys)
	local unit = keys.unit
	local attacker = keys.attacker
	local caster = keys.caster
	local ability = keys.ability

	local guilt_added = 0
	if unit:GetTeamNumber() == caster:GetTeamNumber() then
		if unit:IsHero() or unit:IsBuilding() then
			guilt_added = ability:GetSpecialValueFor("hero_kill_guilt")
		else
			guilt_added = ability:GetSpecialValueFor("creep_kill_guilt")
		end
	end

	local near_caster = (attacker:GetAbsOrigin() - caster:GetAbsOrigin()):Length2D() < ability:GetSpecialValueFor("greater_guilt_radius")
	if near_caster then guilt_added = guilt_added * ability:GetSpecialValueFor("greater_guilt_multiplier") end

	if guilt_added > 0 then
		if not attacker.guilt then attacker.guilt = 0 end
		attacker.guilt = attacker.guilt + guilt_added
		-- print(attacker.guilt)
		if attacker.guilt >= 1 then
			ability:ApplyDataDrivenModifier(caster, attacker, "modifier_not_guilty_debuff", {})
			attacker:SetModifierStackCount("modifier_not_guilty_debuff", caster, attacker.guilt)
		end
	end
end

function onDeath(keys)
	local unit = keys.unit
	local attacker = keys.attacker
	local caster = keys.caster
	-- print("unit death")

	if attacker:GetTeamNumber() == caster:GetTeamNumber() and unit.guilt then
		-- print("reducing guilt")
		-- print(unit.guilt)
		unit.guilt = unit.guilt / 2
		-- print(unit.guilt)
		if unit.guilt >= 1 then -- This code is really unreliable for some reason
			unit:SetModifierStackCount("modifier_not_guilty_debuff", caster, unit.guilt)
		else
			unit:RemoveModifierByName("modifier_not_guilty_debuff")
		end
	end
end

function resetGuiltModifier(keys)
	local unit = keys.target
	local ability = keys.ability
	local caster = keys.caster
	if unit.guilt and unit.guilt >= 1 then
		ability:ApplyDataDrivenModifier(caster, unit, "modifier_not_guilty_debuff", {})
		unit:SetModifierStackCount("modifier_not_guilty_debuff", caster, unit.guilt)
	else
		unit:RemoveModifierByName("modifier_not_guilty_debuff")
	end
end