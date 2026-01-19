# ref: https://sugi.sakura.ne.jp/c/180505a.html
function _change_brightness () {
    sudo sh -c "echo $1 > /sys/class/backlight/intel_backlight/brightness"
}
alias cbr='_change_brightness'
function _look_brightness () {
    cat /sys/class/backlight/intel_backlight/brightness
}
alias lbr='_look_brightness'
