local eventTypes = hs.eventtap.event.types
local isSelectingTerminalText = false
local hasTerminalTextSelection = false

hs.autoLaunch(true)

local function handleTerminalInputEvent(event)
    if hs.application.frontmostApplication():bundleID() ~= "com.apple.Terminal" then
        return false
    end

    local eventType = event:getType()
    local flags = event:getFlags()
    if
        eventType == eventTypes.keyDown
        and event:getKeyCode() == hs.keycodes.map.c
        and flags.cmd
        and not flags.alt
        and not flags.ctrl
        and not flags.shift
    then
        local focusedElement = hs.uielement.focusedElement()
        local selectedText = focusedElement and focusedElement:selectedText()
        if hasTerminalTextSelection or (selectedText and selectedText ~= "") then
            return false
        end

        -- tmux owns ordinary mouse selections, so Terminal's Copy command cannot see them.
        flags.cmd = nil
        flags.ctrl = true
        event:setFlags(flags)
        return false
    end

    if eventType == eventTypes.leftMouseDown and flags.alt then
        isSelectingTerminalText = true
    end

    if isSelectingTerminalText then
        flags.alt = nil
        flags.fn = true
        event:setFlags(flags)

        if eventType == eventTypes.leftMouseDragged then
            hasTerminalTextSelection = true
        end

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
        eventTypes.keyDown,
        eventTypes.leftMouseDown,
        eventTypes.leftMouseDragged,
        eventTypes.leftMouseUp,
    }, handleTerminalInputEvent)
    :start()
