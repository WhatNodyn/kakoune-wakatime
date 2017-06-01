# wakatime.kak

This plugin commits your time spent in Kakoune to [WakaTime](https://wakatime.com)!
It'll try to use the system-wide WakaTime executable, a locally-installed one, or to download it itself. If it doesn't manage any of this, it should display an error, although UI elements in Kakoune might get a bit unpredictable with timings. Either way, things will be logged in the \*debug\* buffer, so check it when installing the plugin.

Basically, once WakaTime is configured, you shouldn't have to manipulate the plugin, unless you want to disable it temporarily, which you can do with `rmhooks global WakaTime`.

## Installing

You may put `wakatime.kak` in your autoload repository, located at `$XDG_CONFIG_HOME/kak/autoload`, or in the system autoload directory, at `/usr/share/kak/autoload`, or one of their subdirectories. Beware as a system-wide installation will only match with a system-wide installation of WakaTime itself.

## Added keywords

 - option `wakatime_file`: The path to your WakaTime configuration file. (Default: `~/.wakatime.cfg`)
 - option `wakatime_options`: The contents of this option will be appended when calling the WakaTime CLI.

## Dependencies

 - `python` (Any version should work, this is a dependency of the WakaTime CLI)
 - `wakatime` (We can download it ourselves if the required packages are present)
 - `unzip` (Needed only to download WakaTime if not installed)
 - `wget` (Needed only to download WakaTime if not installed)
