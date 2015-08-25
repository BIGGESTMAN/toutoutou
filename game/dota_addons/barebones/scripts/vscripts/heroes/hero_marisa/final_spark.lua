require "heroes/hero_marisa/sparks"

function finalSparkStart(keys)
	local caster = keys.caster
	startSpark(caster, keys.ability, "modifier_final_spark", "modifier_final_spark_stun", false, caster:GetForwardVector(), caster:FindAbilityByName("final_spark"), "particles/marisa/final_spark.vpcf")
end

-- local final_damage = damage
-- if unit:HasModifier("modifier_master_spark_vulnerability") then
-- 	local damage_amp = unit:GetModifierStackCount("modifier_master_spark_vulnerability", caster) * ability:GetLevelSpecialValueFor("vulnerability_damage_amp", level)
-- 	local damage_amp_max = ability:GetLevelSpecialValueFor("vulnerability_damage_amp_max", level)
-- 	if damage_amp > damage_amp_max then damage_amp = damage_amp_max end
-- 	final_damage = final_damage * (1 + damage_amp / 100)
-- end