#!/usr/bin/env python

import os
import sys
import subprocess

def change_config_file(settings_path, table):
    lines = []
    try:
        with open(settings_path, 'r') as file:
            lines = file.readlines()
    except FileNotFoundError:
        print(f"Creating new file: {settings_path}")
        lines = []

    with open(settings_path, 'w') as file:
        updated_keys = set()
        for line in lines:
            written = False
            for prefix, suffix in table.items():
                if line.startswith(prefix):
                    file.write(f'{prefix}{suffix}\n')
                    updated_keys.add(prefix)
                    written = True
                    break
            if not written:
                file.write(line)
        
        # Add any missing keys
        for prefix, suffix in table.items():
            if prefix not in updated_keys:
                file.write(f'{prefix}{suffix}\n')

def set_cursor(cursor_theme, cursor_size):
    print(f'Trying to set the "{cursor_theme}" ({cursor_size} px) theme')

    # GTK 2, 3 and 4 config files (assumes standard locations)
    gtk2_table = {
        'gtk-cursor-theme-name': f'="{cursor_theme}"',
        'gtk-cursor-theme-size': f'={cursor_size}'
    }
    gtk3_table = {
        'gtk-cursor-theme-name': f'={cursor_theme}',
        'gtk-cursor-theme-size': f'={cursor_size}'
    }
    gtk4_table = gtk3_table

    gtk_tuples = [
        ('~/.gtkrc-2.0', gtk2_table),
        ('~/.config/gtk-3.0/settings.ini', gtk3_table),
        ('~/.config/gtk-4.0/settings.ini', gtk4_table)
    ]
    for gpath, gtable in gtk_tuples:
        change_config_file(os.path.expanduser(gpath), gtable)

    # Update dconf with gsettings (needs existing dconf database)
    subprocess.run(['gsettings', 'set', 'org.gnome.desktop.interface',
                    'cursor-theme', cursor_theme])
    subprocess.run(['gsettings', 'set', 'org.gnome.desktop.interface',
                    'cursor-size', cursor_size])

    # Check if gsettings changed
    print('From Gsettings (theme and size):')
    subprocess.run(['gsettings', 'get', 'org.gnome.desktop.interface', 'cursor-theme'])
    subprocess.run(['gsettings', 'get', 'org.gnome.desktop.interface', 'cursor-size'])

    # hyprland.conf
    hypr_table = {
        'env = XCURSOR_THEME': f', {cursor_theme}',
        'env = XCURSOR_SIZE': f', {cursor_size}',
        'env = HYPRCURSOR_THEME': f', {cursor_theme}',
        'env = HYPRCURSOR_SIZE': f', {cursor_size}'
    }

    hypr_conf_path = os.path.expanduser('~/.config/hypr/hyprland.conf')
    change_config_file(hypr_conf_path, hypr_table)

    # Hyprctl (also updates dconf)
    print('From Hyprctl (ok or not):')
    subprocess.run(['hyprctl', 'setcursor', f'{cursor_theme}', f'{cursor_size}'])

    # Change Xresources
    xresources_table = {
        'Xcursor.theme': f': {cursor_theme}',
        'Xcursor.size': f': {cursor_size}',
    }

    xresources_path = os.path.expanduser('~/.Xresources')
    change_config_file(xresources_path, xresources_table)

    # Update and check xrdb
    subprocess.run(['xrdb', xresources_path])
    xrdb_out = subprocess.run('xrdb -query | grep Xcursor',
                              shell=True, capture_output=True, text=True)
    print(f'From Xrdb query:\n{xrdb_out.stdout}')

def main():
    cur_theme = sys.argv[1]
    cur_size = sys.argv[2]
    set_cursor(cur_theme, cur_size)

if __name__ == '__main__':
    main()
