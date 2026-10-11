#!/bin/sh
# Drive the Connect IQ simulator from the shell (needs Accessibility + Screen Recording for the terminal).
#   tools/sim.sh run <app>        build for fr245 and launch (start the simulator first: SDK bin/connectiq)
#   tools/sim.sh key start|back|up|down
#   tools/sim.sh play             start simulated GPS/HR data
#   tools/sim.sh shot <name>      screenshot of the watch face -> ~/.cache/ciq/<name>.png
D=$HOME/.cache/ciq; P=$(cd "$(dirname "$0")/.." && pwd)
mkdir -p $D
export PATH=/opt/homebrew/opt/openjdk@21/bin:$PATH
SDK=$(ls -d "$HOME/Library/Application Support/Garmin/ConnectIQ/Sdks"/connectiq-sdk-mac-* | tail -1)
[ -x $D/winid ] || swiftc -O "$P/tools/winid.swift" -o $D/winid
se() { osascript -e "tell application \"System Events\" to tell process \"simulator\" to $1"; }
case $1 in
run) "$SDK/bin/monkeyc" -f $P/$2/monkey.jungle -d fr245 -y $P/developer_key -l 3 -o $D/$2.prg | grep -v '^$' || exit 1
     ("$SDK/bin/monkeydo" $D/$2.prg fr245 > $D/log.txt 2>&1 &); sleep 5 ;;
key) case $2 in start) k=36;; back) k=53;; up) k=126;; down) k=125;; esac
     se "set frontmost to true" >/dev/null; se "perform action \"AXRaise\" of (first window whose name contains \"CIQ Simulator\")" >/dev/null; sleep 0.8
     osascript -e "tell application \"System Events\" to key code $k"; sleep 1 ;;
play) se 'click menu item "Activity Data" of menu "Simulation" of menu bar 1' >/dev/null; sleep 1
      se 'click UI element 19 of window 1' >/dev/null; sleep 1
      se 'click (first button of (first window whose name does not contain "CIQ") whose subrole is "AXCloseButton")' >/dev/null ;;
shot) id=$($D/winid | awk '/CIQ Simulator/{print $1; exit}')
      screencapture -x -o -l$id $D/raw.png && sips -c 560 560 $D/raw.png --out $D/$2.png >/dev/null; cat $D/log.txt ;;
esac
