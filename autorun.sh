#!/usr/bin/env bash

function run {
  if ! pgrep -f $1 ;
  then
    $@&
  fi
}

# Make Caps Lock key as Esc key
# davmail &
# chat-gpt &
autorandr --change
run dropbox start
# xrandr --output eDP-1 --gamma 1.0:0.88:0.76 --brightness 0.6
urxvtd -q -f -o
if ! tmux ls &> /dev/null; then
    urxvt -e tmux
fi
# ~/bin/K480/k480_conf -d /dev/hidraw8 -f on
# xmodmap ~/.Xmodmap
# run dropbox start
# ~/bin/Xrandr_Cosam.sh
# Automatically mount my 2T disc
# sudo mount /dev/sda1 /mnt/SSD-2T/
# run guake --hide
# run krusader
