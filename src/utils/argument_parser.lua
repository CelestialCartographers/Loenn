-- Simple argument parser

local argumentParser = {}
local argumentParserMt = {}
argumentParserMt.__index = {}

function argumentParserMt.__index:addPositional(name)
    table.insert(self.positionals, name)
end

function argumentParserMt.__index:addArgument(options)
    local names = type(options.name) == "table" and options.name or {options.name}

    for _, name in ipairs(names) do
        self.arguments[name] = options
    end
end

function argumentParserMt.__index:addFlag(options)
    options.arity = 0
    options.action = options.action or function()
        return true
    end

    self:addArgument(options)
end

function argumentParserMt.__index:_argumentFinished()
    local flagOptions = self.arguments[self._currentFlag]
    local names = type(flagOptions.name) == "table" and flagOptions.name or {flagOptions.name}
    local valuesToStore = self._flagValues

    -- Manual decision on how to store the data
    if flagOptions.action then
        valuesToStore = flagOptions.action(unpack(valuesToStore))

    else
        -- TODO - Type conversion

        if #valuesToStore == 1 then
            valuesToStore = valuesToStore[1]
        end
    end

    if flagOptions.destination then
        self._result[flagOptions.destination] = valuesToStore
    end

    for _, name in ipairs(names) do
        self._result[name] = valuesToStore
    end

    self._currentFlag = 0
    self._flagValues = {}
end

function argumentParserMt.__index:_errorIfMissingArguments()
    if self._flagValuesRemaining > 0 then
        local flag = self._currentFlag
        local flagOptions = self.arguments[flag]
        local valuesExpected = flagOptions.arity or 1
        local valuesPresent = #self._flagValues

        error(string.format("Missing arguments for flag '%s', got %s expected %s", flag, valuesPresent, valuesExpected))
    end
end

function argumentParserMt.__index:parse(args)
    if not args then
        return
    end

    self._result = {}

    for _, arg in ipairs(args) do
        -- Check in order: new flag > adding flag values > positionals

        if self.arguments[arg] then
            -- Check if previous argument got everything it expects
            self:_errorIfMissingArguments()

            self._currentFlag = arg
            self._flagValuesRemaining = self.arguments[arg].arity or 1
            self._flagValues = {}

            if self._flagValuesRemaining == 0 then
                self:_argumentFinished()
            end

        elseif self._flagValuesRemaining > 0 then
            table.insert(self._flagValues, arg)

            self._flagValuesRemaining = self._flagValuesRemaining - 1

            if self._flagValuesRemaining == 0 then
                self:_argumentFinished()
            end

        else
            -- Not a new argument starter or argument for one, treat as positional
            table.insert(self._result, arg)

            local positionalName = self.positionals[#self._result]

            if positionalName then
                self._result[positionalName] = arg
            end
        end
    end

    -- Check if previous argument got everything it expects
    self:_errorIfMissingArguments()

    print(require("utils").serialize(self._result))

    return self._result
end

function argumentParser.createParser()
    local parser = {}

    parser.positionals = {}
    parser.arguments = {}

    parser._currentFlag = nil
    parser._flagValuesRemaining = 0
    parser._flagValues = {}

    return setmetatable(parser, argumentParserMt)
end

return argumentParser