--[==[

Very basic partial markdown parser.

Format:

{
    {
        tag = "text",
        content = "This is a title"
    },
    {
        tag = "list",
        content = "This is a list element",
        children = {
            {
                tag = "listelement",
                content = "This is an indented list element",
            }
        }
    },
    {
        tag = "list",
        content = {
            "This is a non-indented list element with a ",
            {
                tag = "url",
                content = "link",
                ref = "https://example.com"
            },
            " and all formatting stripped"
        }
    }
}

]==]


local md = {}

local md_mt = {}

local parsers = {}



local formattingchars = {
    ["*"] = "%*",
    ["**"] = "%*%*",
    ["_"] = "_",
    ["~~"] = "~~",
    ["__"] = "__"
}

local function stripFormatting(text)
    repeat
        local done = true

        for c, ec in pairs(formattingchars) do
            local start, stop = string.find(text, ec .. "..-" .. ec)

            if start then
                text = text:sub(1, start - 1) .. text:sub(start + #c, stop - #c) .. text:sub(stop + 1)

                done = false
            end
        end
    until done

    return text
end

local function parseContent(text)
    local hasURL = text:find("%[[^%[%]]+%]%([^%(%)]+%)")

    if hasURL then
        local res = {}
        local pos = 1

        while pos <= #text do
            local start, stop = text:find("%[[^%[%]]+%]%([^%(%)]+%)", pos)
            if start then
                if start > pos then
                    -- Add everything before the URL
                    table.insert(res, stripFormatting(text:sub(pos, start - 1)))
                end

                local label, link = text:sub(start, stop):match("%[([^%[%]]+)%]%(([^%(%)]+)%)")
                table.insert(res, {
                    tag = "url",
                    content = stripFormatting(label),
                    ref = link
                })
                pos = stop + 1
            else
                -- Add remaining text
                table.insert(res, stripFormatting(text:sub(pos)))
                pos = #text + 1
            end
        end

        return res
    else
        return stripFormatting(text)
    end
end


local listchars = table.flip({"-", "*", "+"})

-- List parser
parsers[1] = function(line, state, res, lines, s)
    local spaces, firstchar, content = line:match("^(%s*)(.)%s(.+)")

    local laststate = state[#state]
    local newstate = {}

    if listchars[firstchar] then

        local elem = {}
        elem.tag = "list"

        newstate.elem = elem
        newstate.tag = elem.tag
        newstate.spaces = spaces

        if laststate and laststate.tag == "list" then
            if spaces == laststate.spaces then
                -- Same indentation level
                table.insert(laststate.elem.parent.children, elem)
                elem.parent = laststate.elem.parent

            elseif spaces < laststate.spaces then
                -- Lower indentation level, a parent
                table.insert(laststate.elem.parent.parent.children, elem)
                elem.parent = laststate.elem.parent.parent

            else
                -- Higher indentation level, a child
                laststate.elem.children = laststate.elem.children or {}
                table.insert(laststate.elem.children, elem)
                elem.parent = laststate.elem
            end

        else
            table.insert(res, elem)
            elem.parent = {children = res}
        end

        elem.content = parseContent(content)

        table.insert(state, newstate)

        return true
    else
        -- Drop all recent lists from the states
        while #state > 0 do
            if state[#state].tag == "list" then
                table.remove(state, #state)

            else
                break
            end
        end

        return false
    end
end

-- Break parser
parsers[2] = function(line, state, res, lines, s)
    if line == "" then
        table.insert(res, {tag = "space"})
        return true
    end

    return false
end

-- Text parser
parsers[3] = function(line, state, res, lines, s)
    table.insert(res, {tag = "text", content = parseContent(line)})

    return true
end

function md.parse(s)
    if type(s) ~= "string" then
        return nil, "invalid markdown input: " .. s
    end

    local res = {}

    local lines = s:gsub("\r\n", "\n"):split("\n", nil, false)()

    local state = {}

    for _, line in ipairs(lines) do
        for _, parser in ipairs(parsers) do
            if parser(line, state, res, lines, s) then
                break
            end
        end
    end

    return res
end

function md_mt.__call(lib, s)
    return lib.parse(s)
end

setmetatable(md, md_mt)

return md