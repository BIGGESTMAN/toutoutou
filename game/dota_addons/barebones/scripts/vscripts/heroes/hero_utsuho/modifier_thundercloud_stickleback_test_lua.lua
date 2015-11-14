modifier_thundercloud_stickleback_test_lua = class({})

function modifier_thundercloud_stickleback_test_lua:DeclareFunctions()
	return {MODIFIER_EVENT_ON_MANA_GAINED}
end

function modifier_thundercloud_stickleback_test_lua:OnManaGained(params)
	print("Mana Gained: Lua -----------------------------------")
	for k,v in pairs(params) do
		print(k,v)
	end
end