local reader = require("lib.yaml.reader")

local yaml = {}

yaml.read = reader.eval

return yaml