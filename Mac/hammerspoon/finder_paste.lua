local function saveImage(png, image)
    local ok, directory, details = hs.osascript.applescript([[
        tell application "Finder"
            try
                return POSIX path of (insertion location as alias)
            -- Virtual views such as Recents cannot be converted to a folder alias.
            on error number -1700
                return POSIX path of (path to downloads folder)
            end try
        end tell
    ]])
    if not ok then
        hs.alert.show(details.OSAScriptErrorMessageKey)
        return
    end

    local destination = directory .. "image.png"
    local index = 1
    while hs.fs.symlinkAttributes(destination) do
        destination = directory .. "image" .. index .. ".png"
        index = index + 1
    end

    local saved
    if png then
        -- Keep the original PNG bytes, including resolution and color metadata.
        local file, message = io.open(destination, "wb")
        if not file then
            hs.alert.show(message)
            return
        end
        local written = file:write(png)
        local closed = file:close()
        saved = written and closed
    else
        saved = image:saveToFile(destination)
    end
    if not saved then
        hs.alert.show("Could not save " .. destination)
    end
end

local function pasteImage(event)
    local flags = event:getFlags()
    if event:getKeyCode() ~= hs.keycodes.map.v or not flags:containExactly({ "cmd" }) then
        return false
    end

    local app = hs.application.frontmostApplication()
    if not app or app:bundleID() ~= "com.apple.finder" then
        return false
    end

    -- A copied image file must keep Finder's native copy, move, and undo behavior.
    for _, types in ipairs(hs.pasteboard.allContentTypes()) do
        for _, contentType in ipairs(types) do
            if contentType == "public.file-url" then
                return false
            end
        end
    end

    local focused = hs.axuielement.systemWideElement():attributeValue("AXFocusedUIElement")
    local role = focused and focused:attributeValue("AXRole")
    if role == "AXTextField" or role == "AXTextArea" or role == "AXComboBox" then
        return false
    end

    local png = hs.pasteboard.readDataForUTI("public.png")
    local image = not png and hs.pasteboard.readImage()
    if not png and not image then
        return false
    end

    -- Finder's first automation permission prompt must not block the keyboard hook.
    hs.timer.doAfter(0, function()
        saveImage(png, image)
    end)
    return true
end

return hs.eventtap.new({ hs.eventtap.event.types.keyDown }, pasteImage):start()
