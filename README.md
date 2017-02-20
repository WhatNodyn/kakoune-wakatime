# wakatime.kak

This plugin commits your time spent in Kakoune to [WakaTime](https://wakatime.com)!
It'll try to use the system-wide WakaTime executable, a locally-installed one, or to download it itself. If it doesn't manage any of this, it should
display an error, although UI elements in Kakoune might get a bit unpredictable with timings. Either way, things will be logged in
the \*debug\* buffer, so check it when installing the plugin.

Basically, once WakaTime is configured, you shouldn't have to manipulate the plugin, unless you want to disable it temporarily.

## Installing

Just drop `wakatime.kak` in its own folder in your `autoload` directory.
You might need to write `.wakatime.cfg` yourself if you don't use WakaTime anywhere else.

## Added keywords

 - option `wakatime_file`: The path to your WakaTime configuration file. (Default: `~/.wakatime.cfg`)
 - option `wakatime_options`: The contents of this option will be appended when calling the WakaTime CLI.
 - option `wakatime_version`: Contains the plugin's version. Should not be modified.
 - option `wakatime_command`: The command ran when sending heartbeats. Computed at startup time.
 - option `wakatime_plugin`: The path of the directory containing `wakatime.kak`. You shouldn't modify this.
 - option `wakatime_beat_rate`: The amount of time to be waited between "timeout" heartbeats, do not modify this.
 - option `wakatime_last_file`, `wakatime_last_beat`: This contains info about the last beat. You shouldn't touch it.
 - hidden function `wakatime-create-config`: This is supposed to create the config file if it didn't exist, but it's a Work In Progress.
 - hidden function `wakatime-heartbeat`: As said on the tin, this sends an heartbeat.
 - hidden function `wakatime-init`: This is ran at startup to configure wakatime.kak.
 - hook group `WakaTime`: All hooks related to WakaTime save for...
 - hook group `WakaTimeConfig`: This is only used on initial configuration, if `wakatime-create-config` worked, at least.

## Dependencies

 - `coreutils`
 - `grep`
 - `python` (Any version should work, this is a dependency of the WakaTime CLI)
 - `unzip` (Needed only to download WakaTime locally)
 - `wakatime` (We can download it ourselves if the required packages are present)
 - `wget` (Needed only to download WakaTime locally)
 - `which`
