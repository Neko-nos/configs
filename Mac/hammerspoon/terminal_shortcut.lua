local function remapCommandKey(key, shouldRemap)
    local keyCode = hs.keycodes.map[key]

    local function handleKey(event)
        local app = hs.application.frontmostApplication()
        if not app or app:bundleID() ~= "com.apple.Terminal" then
            return false
        end

        local flags = event:getFlags()
        if
            event:getKeyCode() == keyCode
            and flags.cmd
            and not flags.alt
            and not flags.ctrl
            and not flags.shift
            and (not shouldRemap or shouldRemap())
        then
            flags.cmd = nil
            flags.ctrl = true
            event:setFlags(flags)
        end

        return false
    end

    return hs.eventtap.new({ hs.eventtap.event.types.keyDown }, handleKey):start()
end

return remapCommandKey
