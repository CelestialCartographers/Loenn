local utils = require("utils")
local layerHandlers = require("layer_handlers")
local languageRegistry = require("language_registry")

local formUtils = {}

-- Remove values that should never be available in form
local globallyFilteredKeys = {
    _type = true
}

local function getLanguageKey(key, language, default)
    if language[key]._exists then
        return tostring(language[key])
    end

    return default
end

local function getItemFieldOrder(handler, ...)
    local fieldOrder = utils.callIfFunction(handler and handler.fieldOrder, ...) or {}

    return utils.deepcopy(fieldOrder)
end

local function getItemFieldInformation(handler, ...)
    local fieldInformation = utils.callIfFunction(handler and handler.fieldInformation, ...) or {}

    return utils.deepcopy(fieldInformation)
end

local function getItemLanguage(handler, language, ...)
    if handler and handler.languageData then
        local itemLanguage, fallbackLanguage = handler.languageData(language, ...)

        return itemLanguage, fallbackLanguage or itemLanguage
    end

    return language, language
end

local function getItemIgnoredFields(handler, layer, item)
    local ignored = utils.callIfFunction(handler and handler.ignoredFields, layer, item) or {}
    local ignoredSet = {}

    for _, name in ipairs(ignored) do
        ignoredSet[name] = true
    end

    return ignoredSet
end

-- Prepare for entities/triggers/decals etc.
-- Sets up everything based on handler functions and options
function formUtils.prepareFormData(handler, data, options, handlerArguments)
    local language = languageRegistry.getLanguage()
    local dummyData = {}

    local tooltipPath = options.tooltipPath or {"attributes", "description"}
    local namePath = options.namePath or {"attributes", "name"}

    local addMissingToFieldOrder = options.addMissingToFieldOrder

    local fieldsAdded = {}
    local fieldInformation = getItemFieldInformation(handler, unpack(handlerArguments))
    local fieldOrder = getItemFieldOrder(handler, unpack(handlerArguments))
    local fieldIgnored = getItemIgnoredFields(handler, unpack(handlerArguments))

    local fieldLanguage, fallbackLanguage = getItemLanguage(handler, language, unpack(handlerArguments))
    local languageTooltips = utils.getPath(fieldLanguage, tooltipPath)
    local languageNames = utils.getPath(fieldLanguage, namePath)
    local fallbackTooltips = utils.getPath(fallbackLanguage, tooltipPath)
    local fallbackNames = utils.getPath(fallbackLanguage, namePath)

    for _, field in ipairs(fieldOrder) do
        local value = data[field]

        if value ~= nil or fieldInformation.options then
            local humanizedName = utils.humanizeVariableName(field)
            local displayName = getLanguageKey(field, languageNames, getLanguageKey(field, fallbackNames, humanizedName))
            local tooltip = getLanguageKey(field, languageTooltips, getLanguageKey(field, fallbackTooltips))

            if not fieldInformation[field] then
                fieldInformation[field] = {}
            end

            fieldsAdded[field] = true
            dummyData[field] = utils.deepcopy(value)
            fieldInformation[field].displayName = displayName
            fieldInformation[field].tooltipText = tooltip
        end
    end

    -- Find all fields that aren't added yet and prepare them for alphabetical sorting
    -- Some fields should not be exposed automatically
    -- Any fields already added should not be added again
    local missingFields = {}

    for field, value in pairs(data) do
        if not globallyFilteredKeys[field] and not fieldIgnored[field] and not fieldsAdded[field] then
            local humanizedName = utils.humanizeVariableName(field)
            local displayName = getLanguageKey(field, languageNames, getLanguageKey(field, fallbackNames, humanizedName))

            fieldsAdded[field] = true

            table.insert(missingFields, {field, value, displayName})
        end
    end

    -- Add all fields that have options, but have not yet been added
    for field, info in pairs(fieldInformation) do
        if info.options and not globallyFilteredKeys[field] and not fieldIgnored[field] and not fieldsAdded[field] then
            local value = data[field]
            local humanizedName = utils.humanizeVariableName(field)
            local displayName = getLanguageKey(field, languageNames, getLanguageKey(field, fallbackNames, humanizedName))

            table.insert(missingFields, {field, value, displayName})
        end
    end

    if addMissingToFieldOrder then
        -- Sort by display name
        table.sort(missingFields, function(a, b)
            return a[3] < b[3]
        end)
    end

    -- Add all missing fields
    for _, missing in pairs(missingFields) do
        local field, value, displayName = unpack(missing)
        local tooltip = getLanguageKey(field, languageTooltips, getLanguageKey(field, fallbackTooltips))

        if addMissingToFieldOrder then
            table.insert(fieldOrder, field)
        end

        if not fieldInformation[field] then
            fieldInformation[field] = {}
        end

        dummyData[field] = utils.deepcopy(value)
        fieldInformation[field].displayName = displayName
        fieldInformation[field].tooltipText = tooltip
    end

    return dummyData, fieldInformation, fieldOrder
end

return formUtils