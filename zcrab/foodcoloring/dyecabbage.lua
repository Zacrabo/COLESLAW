function apply(input)
	local cfg = root.itemConfig(input).config
	local params = input.parameters or {}
	
	local purpleItem = params.zcrab_dyepurple or cfg.zcrab_dyepurple
	
	if purpleItem then
		input.name = purpleItem
	end
	
	return input, 1
end
