require "heroes/hero_marisa/sparks"

function masterSparkStart(keys)
	local caster = keys.caster
	startSpark(caster, keys.ability, "modifier_master_spark", "modifier_master_spark_slow", caster:GetForwardVector(), caster:FindAbilityByName("master_spark"), "particles/marisa/master_spark.vpcf")

	local double_spark_ability = caster:FindAbilityByName("double_spark")
	double_spark_ability:StartCooldown(double_spark_ability:GetCooldown(double_spark_ability:GetLevel()))
end

function onUpgrade(keys)
	local caster = keys.caster
	local ability = keys.ability
	local double_spark_ability = caster:FindAbilityByName("double_spark")
	double_spark_ability:SetLevel(ability:GetLevel())
end