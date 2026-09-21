local eventTypes = hs.eventtap.event.types
local isSelectingTerminalText = false
local hasTerminalTextSelection = false

local function hasSelection()
    local focusedElement = hs.uielement.focusedElement()
    local selectedText = focusedElement and focusedElement:selectedText()
    return hasTerminalTextSelection or (selectedText and selectedText ~= "")
end

local function handleMouseEvent(event)
    if hs.application.frontmostApplication():bundleID() ~= "com.apple.Terminal" then
        return false
    end

    local eventType = event:getType()
    local flags = event:getFlags()
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

-- require caches the returned table, keeping the event tap alive without a global.
return {
    hasSelection = hasSelection,
    tap = hs.eventtap
        .new({ eventTypes.leftMouseDown, eventTypes.leftMouseDragged, eventTypes.leftMouseUp }, handleMouseEvent)
        :start(),
}
