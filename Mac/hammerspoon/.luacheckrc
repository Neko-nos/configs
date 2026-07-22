-- ref: https://github.com/Hammerspoon/hammerspoon/blob/master/.luacheckrc

--
-- These globals can be set and accessed:
--
globals = {
    "rawrequire",
    "terminalOptionDrag",
}

--
-- These globals can only be accessed:
--
read_globals = {
    "hs",
    "ls",
    "spoon",
}

--
-- Warnings to ignore:
--
ignore = {
    "631" -- Line is too long.
}
