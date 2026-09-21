require("hs.ipc")

local eventTypes = hs.eventtap.event.types
local pendingClick
local remappedClick = false
local externalLink

local function clickContext(element)
    local context = {}
    while element do
        local role = element:attributeValue("AXRole")
        if role == "AXSheet" or role == "AXDialog" or element:attributeValue("AXSubrole") == "AXDialog" then
            context.dialog = true
        elseif role == "AXLink" then
            local url = element:attributeValue("AXURL")
            if url and url.url:match("^https?://") then
                context.url = url.url
            end
        end
        element = element:attributeValue("AXParent")
    end
    return context
end

local function handleClick(event)
    local eventType = event:getType()
    if externalLink and eventType == eventTypes.leftMouseUp then
        hs.urlevent.openURL(externalLink)
        externalLink = nil
        return true
    end

    local app = hs.application.frontmostApplication()
    if not app or app:bundleID() ~= "com.microsoft.VSCode" then
        pendingClick = nil
        remappedClick = false
        return false
    end

    if eventType == eventTypes.keyDown then
        if
            pendingClick
            and clickContext(hs.axuielement.systemWideElement():attributeValue("AXFocusedUIElement")).dialog
        then
            pendingClick.time = hs.timer.secondsSinceEpoch()
        else
            pendingClick = nil
        end
        return false
    end

    local flags = event:getFlags()
    if eventType == eventTypes.leftMouseDown then
        remappedClick = flags.ctrl and not flags.cmd and not flags.alt and not flags.shift
        local context = clickContext(hs.axuielement.systemElementAtPosition(event:location()))
        -- A trusted-domain confirmation belongs to the original link click.
        if context.dialog then
            if pendingClick then
                pendingClick.time = hs.timer.secondsSinceEpoch()
            end
            remappedClick = false
        else
            pendingClick = { pid = app:pid(), external = remappedClick, time = hs.timer.secondsSinceEpoch() }
            -- Links inside browser pages bypass VS Code's external URI opener.
            if remappedClick and context.url then
                externalLink = context.url
                pendingClick = nil
                remappedClick = false
                return true
            end
        end
    end

    if remappedClick then
        -- VS Code only activates links with Cmd; the opener retains the original Ctrl intent.
        flags.ctrl = nil
        flags.cmd = true
        event:setFlags(flags)
    end
    if eventType == eventTypes.leftMouseUp then
        remappedClick = false
    end
    return false
end

local function consumeClick(pid)
    local click = pendingClick
    if click and click.pid == pid then
        pendingClick = nil
        -- A cancelled click must not redirect a later background URL request.
        if hs.timer.secondsSinceEpoch() - click.time < 5 and click.external then
            return "external"
        end
    end
    return "integrated"
end

return {
    consumeClick = consumeClick,
    tap = hs.eventtap
        .new(
            { eventTypes.keyDown, eventTypes.leftMouseDown, eventTypes.leftMouseUp, eventTypes.leftMouseDragged },
            handleClick
        )
        :start(),
}
