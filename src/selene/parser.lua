local selenep = {}

local timeout

-------------------------------------------------------------------------------
-- Taken from text.lua and improved
local function trim(value) -- from http://lua-users.org/wiki/StringTrim
  local from = string.match(value, "^%s*()")
  return from > #value and "" or string.match(value, ".*%S", from)
end

local escapable = { "'", '"' }
local specialchars = { "(", ")", ":", "?", ",", "+", "-", "*", "%", "^", "&", "~", "|" }
local doublechars = { "/", "<", ">", "$" }
local lambdachars = { "-", "=" }
local assignchars = { "+", "-", "*", "/", "%", "^", "&", "|", ">", "<", ":", "~", "//", "<<", ">>", ".." }

do
  local function transform(t)
    local newT = {}
    for i = 1, #t do
      newT[t[i]] = true
    end
    return newT
  end

  escapable = transform(escapable)
  specialchars = transform(specialchars)
  doublechars = transform(doublechars)
  lambdachars = transform(lambdachars)
  assignchars = transform(assignchars)
end

local function tokenize(value, stripcomments, utime)
  if stripcomments == nil then stripcomments = true end
  local tokens, token, lines = {[0]={}}, "", 1
  local escaped, quoted, start = false, false, -1
  local waiting
  for i = 1, #value do
    if timeout and utime then
      if timeout.time() >= utime + timeout.wait() then
        timeout.yield()
        utime = timeout.time()
      end
    end
    local char = string.sub(value, i, i)

    if escaped and not escapable[quoted] then
      escaped = false
    end

    -- process last entry without touching the current char
    if not quoted and token == "." and tokens[#tokens][1] == ".." and waiting == false and not string.find(char, "^%d$") then
      waiting = nil
      tokens[#tokens][1] = tokens[#tokens][1] .. token
      token = ""
    end

    if escaped then -- escaped character
      escaped = false
      token = token .. char
    elseif char == "\\" and quoted and escapable[quoted] then -- escape character?
      escaped = true
      token = token .. char
    elseif char == "\n" and quoted == "--" then
      quoted = false
      if token ~= "" then
        if not stripcomments then
          table.insert(tokens, {token, lines})
        end
        token = ""
      end
      lines = lines + 1
    elseif char == "]" and quoted and string.find(token, "%]=*$") and string.find(quoted, "^%-%-%[=*%[") and #string.match(token, "%]=*$") == #quoted - 3 then
      quoted = false
      token = token .. char
      if stripcomments then
        for w in token:gmatch("\n") do
          lines = lines + 1
        end
      else
        table.insert(tokens, {token, lines, {}})
        for w in token:gmatch("\n") do
          lines = lines + 1
          table.insert(tokens[#tokens][3], lines)
        end
      end
      token = ""
    elseif char == "[" and quoted == "--" and string.find(token, "%-%-%[=*$") then
      local s = string.match(token, "%[=*$")
      quoted = quoted .. s .. char
      token = token .. char
    elseif char == quoted and escapable[char] then -- end of quoted string
      quoted = false
      token = token .. char
      table.insert(tokens, {token, lines})
      token = ""
    elseif char == "]" and quoted and string.find(token, "%]=*$") and string.find(quoted, "^%[=*%[") and #(string.match(token, "%]=*$") .. char) == #quoted then
      quoted = false
      token = token .. char
      table.insert(tokens, {token, lines, {}})
      for w in token:gmatch("\n") do
        lines = lines + 1
        table.insert(tokens[#tokens][3], lines)
      end
      token = ""
    elseif not quoted and escapable[char] then
      quoted = char
      start = i
      token = token .. char
    elseif char == "-" and not quoted and string.find(token, "%-$") then
      quoted = "-" .. char
      start = i - 1
      token = token .. char
    elseif char == "-" and not quoted and token == "" and tokens[#tokens][1] == "-" then
      token = "--"
      quoted = token
      start = i - 1
      tokens[#tokens] = nil
    elseif char == "[" and not quoted and string.find(token, "%[=*$") then -- derpy quote
      local s = string.match(token, "%[=*$")
      quoted = s .. char
      start = i - #s
      token = token .. char
    elseif not quoted and string.find(char, "%s") then -- delimiter
      if token ~= "" then
        table.insert(tokens, {token, lines})
        token = ""
      end
      if char == "\n" then
        lines = lines + 1
      end
    elseif char == "." and not quoted and token == "" and tokens[#tokens][1] == ".." then
      waiting = true
      token = "."
    elseif char == "=" and not quoted and token == "" and assignchars[tokens[#tokens][1]] then
      tokens[#tokens][1] = tokens[#tokens][1] .. char
    elseif not quoted and token == "" and ((char == ">" and lambdachars[tokens[#tokens][1]]) or (char == "-" and tokens[#tokens][1] == "<")) then
      tokens[#tokens][1] = tokens[#tokens][1] .. char
    elseif char == ">" and not quoted and lambdachars[token] then
      table.insert(tokens, {token .. char, lines})
      token = ""
    elseif not quoted and char == "." then
      if waiting == false and string.sub(token, #token) == "." then
        token = string.sub(token, 1, #token - 1)
        if token and token ~= "" then
          table.insert(tokens, {token, lines})
          token = ""
        end
        table.insert(tokens, {"..", lines})
        waiting = nil
      else
        token = token .. char
        waiting = true
      end
    elseif not quoted and doublechars[char] then
      if waiting == false and token == "" and tokens[#tokens][1] == char then
        tokens[#tokens][1] = tokens[#tokens][1] .. char
        waiting = nil
      else
        if token ~= "" then
          table.insert(tokens, {token, lines})
          token = ""
        end
        table.insert(tokens, {char, lines})
        waiting = true
      end
    elseif not quoted and specialchars[char] then
      if token ~= "" then
        table.insert(tokens, {token, lines})
        token = ""
      end
      table.insert(tokens, {char, lines})
    else -- normal char
      token = token .. char
    end
    if waiting then
      waiting = false
    else
      waiting = nil
    end
  end
  if quoted then
    return nil, "unclosed quote at index " .. start
  end
  if token ~= "" then
    table.insert(tokens, {token, lines})
    lines = lines + 1
  end
  for i = 1, #tokens do
    if tokens[i][3] == nil then tokens[i][3] = false end
  end
  return tokens, utime
end

-------------------------------------------------------------------------------

local varPattern = "^[%a_][%w_]*$"
--local lambdaParPattern = "("..varPattern..")((%s*,%s*)("..varPattern.."))*"

local function isVar(t)
  for str in t:gmatch("([^.]+)") do
    if not str:find(varPattern) then
      return false
    end
  end
  return true
end

local function perror(msg, lvl)
  msg = msg or "unknown error"
  lvl = lvl or 1
  error("[Selene] error while parsing: " .. msg, lvl)
end

local function bracket(tokens, plus, minus, step, result, incr, start)
  local curr = tokens[step][1]
  local brackets = start or 1
  local res = { result }
  while brackets > 0 do
    if not curr then
      perror("missing " .. (incr > 0 and "closing" or "opening") .. " bracket '" .. minus .. "'")
    end
    if curr == plus then
      brackets = brackets + 1
    end
    if curr == minus then
      brackets = brackets - 1
    end
    if brackets > 0 then
      if incr > 0 then
        table.insert(res, curr)
      else
        table.insert(res, 1, curr)
      end
      step = step + incr
      curr = tokens[step][1]
    end
  end
  return table.concat(res, " "), step
end

local function split(self, sep)
  local t = {}
  local i = 1
  for str in self:gmatch(string.format("([^%s]+)", sep)) do
    t[i] = trim(str)
    i = i + 1
  end
  return t
end

local function tryAddReturn(code, stripcomments)
  local tokens, msg = tokenize(code, stripcomments)
  if not tokens then
    perror(msg)
  end
  msg = nil
  for _, part in ipairs(tokens) do
    if part[1]:find("^return$") then
      return code
    end
  end
  return "return " .. code
end

local function findLambda(tokens, i, part, line, stripcomments)
  local params = {}
  local step = i - 1
  local inst, step = bracket(tokens, ")", "(", step, "", -1)

  local cond = {string.match(inst, "([^!]*)!(.*)")}
  inst = cond[1] or inst
  local params = split(inst, ",")

  if #cond > 1 then
    table.remove(cond, 1)
    cond = "function(" .. table.concat(params, ",") .. ") return " .. table.concat(cond) .. " end"
  else
    cond = "nil"
  end

  local start = step
  step = i + 1
  local funcode, step = bracket(tokens, "(", ")", step, "", 1)
  local stop = step
  if not funcode:find("return", 1, true) then
    funcode = "return " .. funcode
  else
    funcode = tryAddReturn(funcode, stripcomments)
  end
  for _, s in ipairs(params) do
    if not (s:find(varPattern) or s == "...") then
      perror("invalid lambda at index " .. i .. " (line " .. line .. "): invalid parameters: " .. table.concat(params, ",") .. " - parameter " .. s)
    end
  end
  local func = string.format("(_selene._newFunc(function(%s) %s end, %d, %s))", table.concat(params, ","), funcode, #params, cond)
  for i = start, stop do
    table.remove(tokens, start)
  end
  table.insert(tokens, start, {func, line, false})
  return start, start
end

local function findDollars(tokens, i, part, line)
  local curr = tokens[i + 1][1]
  if tokens[i - 1][1] and tokens[i - 1][1]:find("[:%.]$") then
    tokens[i - 1][1] = tokens[i - 1][1]:sub(1, #(tokens[i - 1][1]) - 1)
    tokens[i][1] = "()"
    return i - 1, i
  elseif curr:find("^[({\"']") or curr:find("^%[=*%[") then
    tokens[i][1] = "_selene._new"
  elseif curr:find("^l") then
    tokens[i][1] = "_selene._newList"
    table.remove(tokens, i + 1)
  elseif curr:find("^f") then
    tokens[i][1] = "_selene._newFunc"
    table.remove(tokens, i + 1)
  elseif curr:find("^s") then
    tokens[i][1] = "_selene._newString"
    table.remove(tokens, i + 1)
  elseif curr:find("^o") then
    tokens[i][1] = "_selene._newOptional"
    table.remove(tokens, i + 1)
  elseif curr:find("^i") then
    tokens[i][1] = "_selene._newIterable"
    table.remove(tokens, i + 1)
  else
    perror("invalid $ at index " .. i .. " (line " .. line .. ")")
  end
  return i, i
end

local function findSelfCall(tokens, i, part, line)
  if not tokens[i + 2] then tokens[i + 2] = {"", line, false} end
  if tokens[i + 1][1]:find(varPattern) and not tokens[i + 2][1]:find("(", 1, true) and not (tokens[i - 1][1] and tokens[i - 1][1]:find("^:")) then
    tokens[i + 1][1] = tokens[i + 1][1] .. "()"
    return i + 1, i + 2
  end
  return false
end

local function findTernary(tokens, i, part, line)
  local step = i - 1
  local cond, step = bracket(tokens, ")", "(", step, "", -1)
  local start = step
  step = i + 1
  local case, step = bracket(tokens, "(", ")", step, "", 1)
  local stop = step
  if not case:find(":", 1, true) then
    perror("invalid ternary at index " .. step .. " (line " .. line .. "): missing colon ':'")
  end
  local trueCase = case:sub(1, case:find(":", 1, true) - 1)
  local falseCase = case:sub(case:find(":", 1, true) + 1)
  local ternary = string.format("(function() if %s then return %s else return %s end end)()", cond, trueCase, falseCase)
  for i = start, stop do
    table.remove(tokens, start)
  end
  table.insert(tokens, start, {ternary, line, false})
  return start, start
end

local function findForeach(tokens, i, part, line)
  local start
  local step = i - 1
  local params = {}
  while not start do
    if not tokens[step] then
      return false
    elseif tokens[step][1] == "for" then
      start = step + 1
    else
      table.insert(params, 1, tokens[step][1])
      step = step - 1
    end
  end
  params = split(table.concat(params), ",")
  step = i + 1
  local stop
  local vars = {}
  while not stop do
    if not tokens[step] then
      return false
    elseif tokens[step][1] == "do" then
      stop = step - 1
    else
      vars[#vars + 1] = tokens[step][1]
      step = step + 1
    end
  end
  for _, p in ipairs(params) do
    if not p:find(varPattern) then
      return false
    end
  end
  local func = string.format("%s in lpairs(%s)", table.concat(params, ","), table.concat(vars, " "))
  for i = start, stop do
    table.remove(tokens, start)
  end
  table.insert(tokens, start, {func, line, false})
  return start, start
end

local function findAssignmentOperator(tokens, i)
  if tokens[i - 1][1] and isVar(tokens[i - 1][1]) then
    tokens[i][1] = " = " .. tokens[i - 1][1] .. " " .. tokens[i][1]:sub(1, #tokens[i][1] - 1)
    return i, i
  end
  return false
end

local function findDollarAssignment(tokens, i, part, line)
  if tokens[i - 1][1] and isVar(tokens[i - 1][1]) then
    tokens[i][1] = " = _selene._new(" .. tokens[i - 1][1] .. ")"
    return i, i
  else
    perror("invalid $$ at index " .. i .. " (line " .. line .. ")")
  end
end

--[[local types = {
  ["nil"] = true,
  ["boolean"] = true,
  ["string"] = true,
  ["number"] = true,
  ["table"] = true,
  ["function"] = true,
  ["thread"] = true,
  ["userdata"] = true,
  ["list"] = true,
  ["map"] = true,
  ["stringlist"] = true,
}

local function findMatch(tChunk, i, part)
  if not tChunk[i + 1]:find("(", 1, true) then
    perror("invalid match at index "..i..": no brackets () found")
  end
  local start = i
  local step = i + 2
  local cases, step = bracket(tChunk, "(", ")", step, "", 1)
  local stop = step
end]]

local keywords = {
  ["->"   ] = findLambda,
  ["=>"   ] = findLambda,
  ["<-"   ] = findForeach,
  ["?"    ] = findTernary,
  [":"    ] = findSelfCall,
  --["match"] = findMatch,
  ["$"    ] = findDollars,
  ["$$"   ] = findDollarAssignment,
  ["+="   ] = findAssignmentOperator,
  ["-="   ] = findAssignmentOperator,
  ["*="   ] = findAssignmentOperator,
  ["/="   ] = findAssignmentOperator,
  ["//="  ] = findAssignmentOperator,
  ["%="   ] = findAssignmentOperator,
  ["^="   ] = findAssignmentOperator,
  ["&="   ] = findAssignmentOperator,
  ["|="   ] = findAssignmentOperator,
  --["~="   ] = findAssignmentOperator,
  [">>="  ] = findAssignmentOperator,
  ["<<="  ] = findAssignmentOperator,
  ["..="  ] = findAssignmentOperator,
  [":="   ] = findAssignmentOperator,
}

local function concatWithLines(tokens)
  local chunktbl = {}
  local last = 0
  local deadlines = {}
  for i, token in ipairs(tokens) do
    local j = token[2]
    if not chunktbl[j] then chunktbl[j] = {} end
    chunktbl[j][#chunktbl[j] + 1] = token[1]
    last = math.max(last, j)
    if token[3] then
      for _, v in ipairs(token[3]) do
        chunktbl[v] = false
        deadlines[v] = j
        last = math.max(last, v)
      end
    end
  end
  for i = 1, last do
    if not chunktbl[i] and chunktbl[i] ~= false then
      chunktbl[i] = {}
    end
  end
  local i = 1
  while i <= #chunktbl do
    if chunktbl[i] ~= false then
      if not deadlines[i] then
        chunktbl[i] = table.concat(chunktbl[i], " ")
        i = i + 1
      else
        chunktbl[deadlines[i]] = chunktbl[deadlines[i]] .. " " .. table.concat(chunktbl[i], " ")
        deadlines[i] = nil
        table.remove(chunktbl, i)
        for k = i + 1, last do
          if deadlines[k] then
            if deadlines[k] >= i then
              deadlines[k - 1] = deadlines[k] - 1
            else
              deadlines[k - 1] = deadlines[k]
            end
            deadlines[k] = nil
          end
        end
      end
    else
      deadlines[i] = nil
      table.remove(chunktbl, i)
      for k = i + 1, last do
        if deadlines[k] then
          if deadlines[k] >= i then
            deadlines[k - 1] = deadlines[k] - 1
          else
            deadlines[k - 1] = deadlines[k]
          end
          deadlines[k] = nil
        end
      end
    end
  end
  return table.concat(chunktbl, "\n")
end

local function parse(chunk, stripcomments)
  if not type(stripcomments) == "boolean" then stripcomments = true end
  local utime
  if timeout then
    utime = timeout.time()
  end
  local tokens, utime = tokenize(chunk, stripcomments, utime)
  if not tokens then
    error(utime)
  end
  local i = 1
  while i <= #tokens do
    local part = tokens[i][1]
    if keywords[part] then
      if not tokens[i + 1] then tokens[i + 1] = {"", tokens[i][2], false} end
      if not tokens[i - 1] then tokens[i - 1] = {"", tokens[i][2], false} end
      local start, stop = keywords[part](tokens, i, part, tokens[i][2], stripcomments)
      if start then
        chunk = nil
        stop = stop or start
        local toInsert = {}
        for count = start, stop do
          local stokens, stokenlines, sskiplines
          stokens, stokenlines, sskiplines, utime = tokenize(tokens[start][1], stripcomments, utime)
          for si, stoken in ipairs(stokens) do
            table.insert(toInsert, { stoken[1], tokens[start][2] + stoken[2] - 1, stoken[3] })
          end
          table.remove(tokens, start)
        end

        for q = #toInsert, 1, -1 do
          table.insert(tokens, start, toInsert[q])
        end
        i = start - 1
      end
    end
    i = i + 1
  end
  return chunk or concatWithLines(tokens)
end

function selenep.parse(chunk, stripcomments)
  return parse(chunk, stripcomments)
end

--[[
  Allows setting a handler in case the sandbox must yield/pause every so often. All three parameters must be callable.
  'func' is the function that will be called to prevent a timeout.
  'time' needs to return the interval in which the function is called.
  'timefunc' must be a function that returns the current time. Its value will be compared to the last call's value to determine whether 'func' needs to be called.
]]
function selenep.setTimeoutHandler(func, time, timefunc)
  timeout = {}
  timeout.yield = func
  timeout.wait = time
  timeout.time = timefunc
end

return selenep
