local RunService = game:GetService('RunService')

local function ezsetup_on_client()
	assert(
		RunService:IsClient(),
		'ocean.new() must be called on the client. If you want to use this on the server, just use the spectrum.'
	)
end

-- module
return table.freeze {
	ezsetup_on_client = table.freeze { assert = ezsetup_on_client },
}
