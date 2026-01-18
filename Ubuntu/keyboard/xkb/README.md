# How to use
1. For `~/.xkb/keymap/map_custom`, first run `setxkbmap -print`, then append `+jp_custom(remap)` to the end of the string inside the `xkb_symbols` include.
   - Note that the `map_custom` in this repository is just for reference; other parts like `geometry` depend on your environment.
2. Add settings to `~/.xkb/symbols/jp_custom` referring to the `jp_custom` file in this repository.
3. Add `xkbcomp -I$HOME/.xkb ~/.xkb/keymap/mykbd $DISPLAY 2> /dev/null` to your .zshrc or similar file (already added in this repository) to complete the setup.
