persona_user = class({})

function persona_user:OnItemEquipped(item)
	if IsServer() then
		print("Item Equipped")
		-- -- print(item)
		-- -- for k,v in pairs(getmetatable(item.__self)) do
		-- 	-- print(k,v)
		-- -- end

		-- print(getmetatable(item).__index)

		-- for k,v in pairs(getmetatable(item).__index.FDesc) do
		-- 	print(k,v)
		-- end
		
		-- for k,v in pairs(item) do
			-- print(k,v)
		-- end
	end
end