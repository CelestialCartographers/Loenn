local physfs = require("physfs")

love.filesystem.createDirectoryUnsandboxed = physfs.mkdir
love.filesystem.mountUnsandboxed = physfs.mount
love.filesystem.isDirectoryUnsandboxed = physfs.isDirectory