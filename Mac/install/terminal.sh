#!/usr/bin/env zsh

# Stop running this script if any error occurs.
set -euo pipefail

script_dir="${${(%):-%N}:A:h}"
terminal_profile="${script_dir}/../default_terminal_profile.terminal"
terminal_profile="${terminal_profile:A}"
# Terminal names imported profiles after the file, regardless of the embedded plist name.
profile_name="${terminal_profile:t:r}"

# Replace the managed profile so repeated installations do not create numbered copies.
osascript - "${profile_name}" <<'APPLESCRIPT'
on run arguments
    set profileName to item 1 of arguments
    tell application "Terminal"
        if exists settings set profileName then
            delete settings set profileName
        end if
    end tell
end run
APPLESCRIPT

open -a Terminal "${terminal_profile}"

# Terminal owns its live preferences, so configure them through the application.
osascript - "${profile_name}" <<'APPLESCRIPT'
on run arguments
    set profileName to item 1 of arguments
    tell application "Terminal"
        set default settings to settings set profileName
        set startup settings to settings set profileName
    end tell
end run
APPLESCRIPT

echo "Imported the ${profile_name} Terminal profile and set it as the startup and default profile."
echo 'Finished Terminal configuration!'
echo

unset -v script_dir
unset -v terminal_profile
unset -v profile_name
