local remapCommandKey = require("terminal_shortcut")

-- Terminal programs need a Control sequence to use nano's undo binding.
return remapCommandKey("z")
