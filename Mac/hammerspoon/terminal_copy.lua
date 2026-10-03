local terminalSelection = require("terminal_selection")
local remapCommandKey = require("terminal_shortcut")

-- tmux owns ordinary mouse selections, so Terminal's Copy command cannot see them.
return remapCommandKey("c", function()
    return not terminalSelection.hasSelection()
end)
