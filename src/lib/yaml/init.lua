local reader = require("lib.yaml.reader")
local writer = require("lib.yaml.writer")

local yaml = {}

yaml.read = reader.eval
yaml.write = writer.write
yaml.serialize = writer.serialize
yaml.validateSerializiation = writer.validateSerializiation

return yaml