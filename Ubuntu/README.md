# Ubuntu
## Basic Setup
- Enable password-less `sudo` execution<br>
  [How to use sudo without entering a password - Qiita](https://qiita.com/RyodoTanaka/items/e9b15d579d17651650b7)

- Run `sudo apt update && sudo apt upgrade -y`

- Change the position of the Dock and other appearance elements for a Mac-like layout<br>
  [Initial settings for Ubuntu (MacOs-tyle) - Qiita](https://qiita.com/momokura/items/33cd6ee525553fc91473)

  - You can also use `dconf-editor` (or `gsettings`, but if you're going to use a GUI anyway, scripting becomes a hassle) to reposition applications<br>
    [13 Things to Do After Installing Ubuntu 20.04 LTS - Qiita](https://qiita.com/outou_hakutou/items/ce06cb3c8c355d5fd87c#dock-%E3%81%AE%E3%82%A2%E3%83%97%E3%83%AA%E3%82%B1%E3%83%BC%E3%82%B7%E3%83%A7%E3%83%B3%E8%A1%A8%E7%A4%BA%E3%83%9C%E3%82%BF%E3%83%B3%E3%82%92%E4%B8%80%E7%95%AA%E4%B8%8A%E3%81%B8%E7%A7%BB%E5%8B%95%E3%81%99%E3%82%8B)

- Install a text editor (like VSCode) to prepare for editing configuration files
  - For VSCode, run `uname -m` to check your architecture (x86_64 etc) and download the correct `.deb` file<br>
    [VSCode on Linux - Official Site](https://code.visualstudio.com/docs/setup/linux)<br>
  - Only install essential extensions and make minimal changes to `settings.json` for now

- Enhance clipboard functionality (equivalent to Clipy on Mac or Clibor on Windows)
  - Use the following GNOME extension:<br>
    [Clipboard Indicator GitHub](https://github.com/Tudmotu/gnome-shell-extension-clipboard-indicator)<br>
  - You can refer to the installation method in the following articles
    - [Install Clipboard Indicator - GNOME Shell Extensions](https://extensions.gnome.org/extension/779/clipboard-indicator/)
    - [2 Linux tools to boost productivity](https://news.mynavi.jp/techplus/article/20201123-1503880/)

- Align screenshot behavior with Mac
    - Changeable from Settings.

# Keyboard Configuration
> [!NOTE]
> My configuration is only for JIS layout, a keyboard layout for Japanese. Other layouts are not tested.<br>
> Also, this configuration is only tested on Ubuntu 20.04 LTS, and it may not work on the later versions due to the Wayland.

The goal is to make key mappings feel like MacOS and let's use `xkb`, `input-remapper`, and `AutoKey` to achieve this.<br>
There are the scripts for my keyboard configuration in the `keyboard` folder, but there are extra settings which requires GUI operations. This `README` file not only describes the scripts but also explains how to set up those extra settings

## Tools
### xkb
[xkb key remapping in Ubuntu - Honmushi blog](https://honmushi.com/2019/01/18/ubuntu-xkb/)<br>
`xmodmap` used to be mainstream, but now somehow the settings for `xmodmap` are frequently overwritten on some background process, so it's better to use `xkb` instead.<br>
[Keyboard Layout Customization in Ubuntu: Solving the xmodmap problem with xkb - Qiita](https://qiita.com/jabberwocky0139/items/40b28406daa6769a9c4d)

### input-remapper
[Input Remapper Usage](https://github.com/sezanzeb/input-remapper/blob/1.5.1/readme/usage.md)<br>
Installation (1.5.1 is the latest version for Ubuntu 20.04)
```console
wget https://github.com/sezanzeb/input-remapper/releases/download/1.5.1/input-remapper-1.5.1.deb
sudo apt install -f ./input-remapper-1.5.1.deb
```

### AutoKey
[AutoKey GitHub](https://github.com/autokey/autokey?tab=readme-ov-file)
#### Installation
You can install simply with `apt` instead of the official method.
```console
sudo apt -y install autokey-gtk
```
- **This will install various packages to the system's Python without making a virtual envrionemt**. So, instead of using the system's Python, use `pyenv` or `uv` to install some Python version later.
- You can safely delete the sample scripts.

#### Usage
[AutoKey Official Docs](https://autokey.github.io/index.html)<br>
- Editing `.py` and `.json` files via VSCode (or any editor you prefer) might be easier to implement than using the Autokey Editor.
  - In this case, you sometimes need to set `usagecount` to a non-zero integer to make it work. If your scripts are correct but don't work, save with Autokey Editor instead. Then, `usagecount` will be correctly adjusted and your scripts will work.
- To start automatically after login, configure from Preferences or edit .config/autokey/autokey.json.

## Key Mapping Examples
- Remap `Henkan/Muhenkan` keys to IME activation/deactivation for a Mac-like experience<br>
  [Mac-like keyboard setup for Ubuntu 22.04.1 LTS - Qiita](https://qiita.com/hayashi001/items/cc09f9a05d0a84513bd7)

- Mapping of `CapsLock`
  - If your `CapsLock` doesn't work, follow the steps below (If you use JIS-Keyboard, it is likely that `Eisu toggle` and `CapsLock` are not separated correclty.)
    - First, check the value of `XKBOPTIONS` in `/etc/default/keyboard`
      - [All configuration for Ubuntu - Qiita](https://qiita.com/Kobayashi2019/items/447a974e6b4493a758ae#caps-lock%E3%82%92ctrl%E3%81%AB%E3%81%99%E3%82%8B-1)
    - Second, use `dconf-editor` and reset the value of `org.gnome.desktop.input-sources xkb-options` to the default value
    - Third, Use `xev` to check encoding. If `Eisu toggle` and `CapsLock` are not separated, you can separate them by mapping `CapsLock` to `Shift + CapsLock` with `gnome-tweaks`.
    - Finally, you can remap `CapsLock` to other keys and vice versa.

- Emulate MacOS-style shortcuts using `Ctrl` and `Command`-like behavior
  - To later achieve Mac-like Command key behavior using the Ctrl key, remap `Eisu toggle` -> `Super`.
  - After that, change the `Super + *` shortcuts in Ubuntu settings to require Shift.
    - If you remap `Eisu toggle` to `Super L`, use `gnome-tweaks` to assign `Super_R` to the Activities Overview<br>
      [Want to disable the 'Activities' screen opening on single press of Super key in Ubuntu - Neo's World](https://neos21.net/blog/2020/03/23-03.html)<br>
  - Then, you can make various changes with AutoKey
    - [Using Cmd and Ctrl on Linux like MacOS - Qiita](https://qiita.com/MTfirst/items/61bc6b8d3da9742b4130)
    - [Create something like Mac's Command key on Linux desktop using Autokey - Qiita](https://qiita.com/Saza-ku/items/e99b50e59b660b528936)
- Referenced the following article for shortcuts:
  - Could use `<ctrl>` + key, but want to use outside the terminal too, so if possible directly with a different key (like `Home`), use that<br>
    [Shortcut collection for using the terminal at lightning speed - Qiita](https://qiita.com/akito/items/d09a2d5b36d4cf7bac6d)

- Make underscore behave like on Mac.
    - On Mac, `Shift + Underscore` produces `underscore`, but since it's rarely used, map `Shift + Underscore` to `backslash` so `backslash` can be used with another key.

- Set up typing \ (backslash) with Alt (remapped Win key from Super -> Alt) + ¥ (Yen key).
    - Similarly change the Yen key using `xkb` (warnings need to be suppressed with `2> /dev/null`).
    - Then just configure with AutoKey (needed to keep `backslash` accessible somewhere for this purpose).
- Enable Mac-like cursor operations with the Alt key as well.
    - Can be done with Autokey.
