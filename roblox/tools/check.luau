--!strict
-- selene: allow(incorrect_standard_library_use)
local process = require("@lune/process")
-- selene: allow(incorrect_standard_library_use)
local net = require("@lune/net")
-- selene: allow(incorrect_standard_library_use)
local fs = require("@lune/fs")
local function run(command: string, arguments: { string })
	print(">", command, table.concat(arguments, " "))
	local result = process.exec(command, arguments)
	if #result.stdout > 0 then
		print(result.stdout)
	end
	if #result.stderr > 0 then
		print(result.stderr)
	end
	assert(result.ok, command .. " failed")
end
fs.writeDir(".tools")
local types = ".tools/globalTypes.d.luau"
if not fs.isFile(types) then
	local response = net.request(
		"https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/1.69.0/scripts/globalTypes.d.luau"
	)
	assert(response.statusCode == 200, "Could not download Roblox type declarations")
	fs.writeFile(types, response.body)
end
run("lune", { "setup" })
run("stylua", { "--check", "src", "tools", "tests" })
run("selene", { "src", "tools", "tests" })
run("lune", { "run", "tools/build.luau" })
run("rojo", { "sourcemap", "default.project.json", "-o", "sourcemap.json" })
run(
	"luau-lsp",
	{ "analyze", "--definitions=" .. types, "--sourcemap=sourcemap.json", "src", "tools", "tests" }
)
run("lune", { "run", "tests/rules.luau" })
run("lune", { "run", "tests/world.luau" })
run("lune", { "run", "tests/models.luau" })
run("lune", { "run", "tests/exteriors.luau" })
print("All offline checks passed. Roblox Studio playtesting is still required.")
