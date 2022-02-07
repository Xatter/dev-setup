#!/bin/bash

# If I am using a VPN like with most remote jobs, if the network disconnects when the display shuts off
# because the computer is going to sleep then I lose my connection and possibly my work or other long
# running tasks unless I'm using screen

# These lines from: https://apple.stackexchange.com/questions/234889/how-to-prevent-cisco-anyconnect-from-disconnecting-when-locking-screen

# Prevent Wifi from sleeping when computer sleeps
cd /System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources
sudo ./airport en0 prefs DisconnectOnLogout=NO

# Prevent sleeping when logged out
sudo pmset -a sleep 0
