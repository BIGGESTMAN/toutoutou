LinkLuaModifier("modifier_demarcation_affected", "heroes/hero_rumia/modifier_demarcation_affected.lua", LUA_MODIFIER_MOTION_NONE )

function demarcationAffectedModifierCreated(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability

	if target:GetTeamNumber() ~= caster:GetTeamNumber() and not target:IsOutOfGame() then
		target:AddNewModifier(caster, ability, "modifier_demarcation_affected", {})
	end
	if target == caster then
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_demarcation_speedboost", {})
	end
end

function demarcationAffectedModifierDestroyed(keys)
	keys.target:RemoveModifierByName("modifier_demarcation_affected")
	keys.target:RemoveModifierByName("modifier_demarcation_speedboost")
end