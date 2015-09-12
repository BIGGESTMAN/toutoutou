require "heroes/hero_marisa/sparks"
require "heroes/hero_marisa/orrerys_sun"

function doubleSparkStart(keys)
	local caster = keys.caster
	local ability = keys.ability
	local direction1 = RotatePosition(Vector(0,0,0), QAngle(0,-17.5,0), caster:GetForwardVector())
	local direction2 = RotatePosition(Vector(0,0,0), QAngle(0,17.5,0), caster:GetForwardVector())

	local master_spark_ability = caster:FindAbilityByName("master_spark")
	master_spark_ability:StartCooldown(master_spark_ability:GetCooldown(master_spark_ability:GetLevel()))
	startSpark(caster, master_spark_ability, "modifier_master_spark", "modifier_master_spark_slow", true, direction1, master_spark_ability, "particles/marisa/master_spark.vpcf")
	startSpark(caster, ability, "modifier_double_spark", "modifier_double_spark_slow", true, direction2, master_spark_ability, "particles/marisa/master_spark.vpcf")

	if caster:HasModifier("modifier_orrerys_sun") then
		print("!")
		fireLasers(caster, caster:FindAbilityByName("orrerys_sun"))
	end
end

function doubleSparkLearned(keys)
	local caster = keys.caster
	local ability = keys.ability
	ability:SetLevel(1)
	caster:SwapAbilities("final_spark", "double_spark", true, true)

	local master_spark_ability = caster:FindAbilityByName("master_spark")
	ability:SetLevel(master_spark_ability:GetLevel())
end