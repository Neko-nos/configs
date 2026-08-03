on run arguments
    set applicationName to item 1 of arguments
    set applicationPath to item 2 of arguments

    tell application "System Events"
        if not (exists login item applicationName) then
            make login item at end with properties {name:applicationName, path:applicationPath, hidden:true}
        end if

        if not (exists login item applicationName) then
            error "macOS did not create the requested login item: " & applicationName
        end if
    end tell
end run
