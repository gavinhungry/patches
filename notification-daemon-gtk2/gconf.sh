#!/bin/bash

gconftool-2 --type boolean --set /apps/notification-daemon/sound_enabled true
gconftool-2 --type string --set /apps/notification-daemon/default_sound "$HOME/.sounds/notification.oga"