local eventTypes = hs.eventtap.event.types
local isSelectingTerminalText = false
local terminalSelectionActive = false

local function handleTerminalMouseEvent(event)
    local application = hs.application.frontmostApplication()
    if application:bundleID() ~= "com.apple.Terminal" then
        return false
    end

    local eventType = event:getType()
    local flags = event:getFlags()
    if eventType == eventTypes.leftMouseDown and flags.alt then
        isSelectingTerminalText = true
        terminalSelectionActive = true
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

    if terminalSelectionActive and eventType == eventTypes.leftMouseDown then
        terminalSelectionActive = false
        local location = event:location()
        local clearSelectionDown = hs.eventtap.event.newMouseEvent(
            eventTypes.leftMouseDown,
            location,
            { "fn" }
        )
        local clearSelectionUp = hs.eventtap.event.newMouseEvent(
            eventTypes.leftMouseUp,
            location,
            { "fn" }
        )
        return true, { clearSelectionDown, clearSelectionUp, event:copy() }
    end

    return false
end

local terminalOptionDrag = hs.eventtap.new({
    eventTypes.leftMouseDown,
    eventTypes.leftMouseDragged,
    eventTypes.leftMouseUp,
}, handleTerminalMouseEvent)

terminalOptionDrag:start()

-- The callback retains the event tap for the lifetime of the Lua environment.
hs.shutdownCallback = function()
    terminalOptionDrag:stop()
end
