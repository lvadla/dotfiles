#!/bin/bash
osascript -e 'activate application "NotificationCenter"
tell application "System Events"
    tell process "NotificationCenter"
        set theWindow to group 1 of UI element 1 of scroll area 1 of window "Notification Center"
        # click theWindow
        set theActions to actions of theWindow
        repeat with theAction in theActions
            if description of theAction is "Close" then
                tell theWindow
                    perform theAction
                end tell
                exit repeat
            end if
        end repeat
    end tell
end tell'