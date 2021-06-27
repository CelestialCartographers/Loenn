-- Load program persistence data
-- Should be easily accessible from code
-- Used to store values between sessions, but not important enough to immediately flush to disk

local config = require("config")
local fileLocations = require("file_locations")

local persistenceBufferTime = 300
local persistence = config.readConfig(fileLocations.getPersistencePath(), persistenceBufferTime)

return persistence