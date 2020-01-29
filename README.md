# kakoune-wakatime

This plugin performs time-tracking in Kakoune with [WakaTime](https://wakatime.com).
It uses the associated CLI (the `wakatime` command) which, if not found in
your `PATH`, it will automatically install in the plugin's directory provided
that you have the required tools (`python`, `unzip` and `wget`/`curl`).

It is however recommended to perform a system-wide installation of the CLI.

## Installing

You may put `kakoune-wakatime` in your autoload repository, located at
`$XDG_CONFIG_HOME/kak/autoload`, or in the system autoload directory, at 
`/usr/share/kak/autoload`, or one of their subdirectories. Beware as a
system-wide installation will only match with a system-wide installation of 
WakaTime itself.

The plugin has also been tested through [plug.kak](https://github.com/andreyorst/plug.kak),
in which case you just need to add the following to your kakrc:

```kak
plug "WhatNodyn/kakoune-wakatime"
```

On startup, if no api_key is available in WakaTime configuration, you will be
prompted to input it.

## Configuration
**NOTE**: While it is possible to disable heartbeats by removing the `WakaTime`
hook group, there isn't a way to restart them without restarting Kakoune for
now

### `wakatime_file` (`str`)
The path to your WakaTime configuration file, if empty (as per the default), let
WakaTime guess.

### `wakatime_options` (`str`)
Arguments to be appended to WakaTime CLI calls

### `wakatime_debug` (`bool`)
Enable debug messages (showing each executed beat)
