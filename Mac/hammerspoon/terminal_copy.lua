local terminalSelection = require("terminal_selection")

local function handleCopy(event)
    if hs.application.frontmostApplication():bundleID() ~= "com.apple.Terminal" then
        return false
    end

    local flags = event:getFlags()
    if
        event:getKeyCode() == hs.keycodes.map.c
        and flags.cmd
        and not flags.alt
        and not flags.ctrl
        and not flags.shift
        and not terminalSelection.hasSelection()
    then
        -- tmux owns ordinary mouse selections, so Terminal's Copy command cannot see them.
        flags.cmd = nil
        flags.ctrl = true
        event:setFlags(flags)
    end

    return false
end

return hs.eventtap.new({ hs.eventtap.event.types.keyDown }, handleCopy):start()
