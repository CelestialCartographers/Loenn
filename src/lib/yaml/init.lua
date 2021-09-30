local reader = require("yaml.reader")

local yaml = {}

yaml.read = reader.eval

return yaml