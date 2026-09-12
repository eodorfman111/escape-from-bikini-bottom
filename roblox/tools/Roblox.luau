--!strict
-- selene: allow(incorrect_standard_library_use)
local roblox = require("@lune/roblox")

-- Lune 0.10.4 omits datatype exports from its bundled declarations.
return (roblox :: unknown) :: {
	Instance: typeof(Instance),
	Vector3: typeof(Vector3),
	Color3: typeof(Color3),
	CFrame: typeof(CFrame),
	Enum: typeof(Enum),
	UDim2: typeof(UDim2),
	serializeModel: ({ Instance }, boolean?) -> string,
	deserializeModel: (string) -> { Instance },
	serializePlace: (DataModel, boolean?) -> string,
	deserializePlace: (string) -> DataModel,
}
