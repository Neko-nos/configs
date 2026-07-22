local eventTypes = hs.eventtap.event.types
local isSelectingTerminalText = false
local hasTerminalTextSelection = false

local function handleTerminalMouseEvent(event)
    if hs.application.frontmostApplication():bundleID() ~= "com.apple.Terminal" then
        return false
    end

    local eventType = event:getType()
    local flags = event:getFlags()
    if eventType == eventTypes.leftMouseDown and flags.alt then
        isSelectingTerminalText = true
        hasTerminalTextSelection = true
    end

    if isSelectingTerminalText then
        flags.alt = nil
        flags.fn = true
        event:setFlags(flags)

        if eventType == eventTypes.leftMouseUp then
            isSelectingTerminalText = false
        end

        return false
    end

    if hasTerminalTextSelection and eventType == eventTypes.leftMouseDown then
        hasTerminalTextSelection = false
        local location = event:location()
        local clearSelectionDown = hs.eventtap.event.newMouseEvent(eventTypes.leftMouseDown, location, { "fn" })
        local clearSelectionUp = hs.eventtap.event.newMouseEvent(eventTypes.leftMouseUp, location, { "fn" })
        return true, { clearSelectionDown, clearSelectionUp, event:copy() }
    end

    return false
end

-- Hammerspoon requires a global reference to keep long-lived objects from being collected.
terminalOptionDrag = hs.eventtap
    .new({
        eventTypes.leftMouseDown,
        eventTypes.leftMouseDragged,
        eventTypes.leftMouseUp,
    }, handleTerminalMouseEvent)
    :start()
