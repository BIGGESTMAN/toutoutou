LinkLuaModifier("modifier_flower_wither_away", "heroes/hero_letty/modifier_flower_wither_away.lua", LUA_MODIFIER_MOTION_NONE )

function setMaxHealth(keys)
	local target = keys.target
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1

	if not target:HasModifier("modifier_flower_wither_away_datadriven") then
		target.flower_wither_health_bonus = target:GetHealthDeficit() * -1
	else
		target.flower_wither_health_bonus = target.flower_wither_health_bonus - target:GetHealthDeficit()
	end
	target:RemoveModifierByName("modifier_flower_wither_away")
	target:AddNewModifier(keys.caster, ability, "modifier_flower_wither_away", {})
	ability:ApplyDataDrivenModifier(keys.caster, target, "modifier_flower_wither_away_datadriven", {})
	target:SetHealth(target:GetMaxHealth())

	local particle = ParticleManager:CreateParticle("particles/letty/flower_wither_away_proc_alt.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
end

function damageTaken(keys)
	local target = keys.unit
	local ability = keys.ability

	if target:HasModifier("modifier_lingering_cold_debuff") then
		target.flower_wither_health_bonus = target.flower_wither_health_bonus - target:GetHealthDeficit()
		target:RemoveModifierByName("modifier_flower_wither_away")
		target:AddNewModifier(keys.caster, ability, "modifier_flower_wither_away", {})
		target:SetHealth(target:GetMaxHealth())

		local particle = ParticleManager:CreateParticle("particles/letty/flower_wither_away_proc_alt.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
	end
end

function removeLuaModifier(keys)
	keys.target:RemoveModifierByName("modifier_flower_wither_away")
	keys.target.flower_wither_health_bonus = nil
end