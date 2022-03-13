local autoIndent = {}

-- with one argument returns the line at the index
-- with no arguments returns the number of lines
local function lines(index)
	if index then
		return vim.api.nvim_buf_get_lines(0, index, index + 1, true)[1]
	else
		return vim.api.nvim_call_function('line', { '$' })
	end
end

local function setopt(name, value)
	return vim.api.nvim_buf_set_option(0, name, value)
end

-- returns the type of indentation for one line
-- if the line is tab indented it returns { tab = true }
-- if the line is space indented it returs { space = <count> }, where count is the number of spaces >= 2
local function lineIndent(line)
	if #line == 0 then return end
	local begin = line:sub(1, 1)
	if begin == '\t' then
		return { tab = true }
	elseif begin == ' ' then
		local indent_count = 0
		for i = 1, #line, 1 do
			if line:sub(i, i) ~= ' ' then break end
			indent_count = indent_count + 1
		end
		if indent_count >= 2 then return { space = indent_count } end
	end
end

local function multiple(a, b)
	if b > a then a, b = b, a end
	if (a % b ~= 0) then return 0 end
	return b
end

local function bufIndent()
	local count = lines()
	local indentsInfo = {}
	for i = 0, count - 1, 1 do
		local newIndent = lineIndent(lines(i))

		if not newIndent then goto continue end

		for _, oldIndent in ipairs(indentsInfo) do
			if oldIndent.tab and newIndent.tab then return { tab = true } end
			if oldIndent.space and newIndent.space then
				local spaceMult = multiple(oldIndent.space, newIndent.space)
				if spaceMult >= 2 and spaceMult % 2 == 0 then return { space = spaceMult } end
			end
		end

		table.insert(indentsInfo, newIndent) 

		::continue::
	end
end

function autoIndent.detect()
	local indent = bufIndent()
	if indent.tab then
		setopt('expandtab', false)
	elseif indent.space ~= 0 then
		setopt('expandtab', true)
		setopt('tabstop', indent.space)
		setopt('softtabstop', indent.space)
		setopt('shiftwidth', indent.space)
	end
end

function autoIndent.setup()
	vim.cmd [[
	augroup autoIndent
		autocmd!
		autocmd BufReadPost * AutoIndent
	augroup END
	]]
end

return autoIndent;
