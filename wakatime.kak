# wakatime.kak version 3.1.2
# By Nodyn

decl str		wakatime_file
decl str		wakatime_options
decl bool		wakatime_debug		false

decl -hidden str	wakatime_version	"3.1.2"
decl -hidden str	wakatime_command
decl -hidden str	wakatime_plugin		%sh{ dirname "$kak_source" }

decl -hidden str	wakatime_beat_rate	120
decl -hidden str	wakatime_last_file
decl -hidden int	wakatime_last_beat


def -hidden	wakatime-create-config %{
	rmhooks global WakaTimeConfig
	prompt "WakaTime API key:" %{
		evaluate-commands %sh{
			eval "$kak_opt_wakatime_command $kak_opt_wakatime_options --config-write api_key \"$kak_text\""
		}
	}
}

def -hidden	wakatime-heartbeat -params 0..1 %{
	evaluate-commands %sh{
		# First, if we're not in a real file, abort.
		if [ "$kak_buffile" = "$kak_bufname" ]; then
			exit
		fi

		# Still here? Let's get the current time.
		this=$(date "+%s")

		# Every command will look like that.
		command="$kak_opt_wakatime_command $kak_opt_wakatime_options --entity \"$kak_buffile\" --time $this"

		# If we have the cursor position, then let's hand it off to WakaTime.
		if [ -n "$kak_cursor_byte_offset" ]; then
			command="$command --cursorpos $kak_cursor_byte_offset"
		fi

		# Let's add the language as Alternate Language, because we have better detection than Kakoune.
		if [ -n "$kak_filetype" ]; then
			command="$command --alternate-language $kak_filetype"
		fi

		# The command is complete, now let's see if we have to send a heartbeat?
		if [ "$kak_buffile" != "$kak_opt_wakatime_last_file" ]; then
			# The focused file changed, update the variable taking care of that and send an heartbeat.
			if [ "$kak_opt_wakatime_debug" = "true" ]; then
				echo "echo -debug '[WakaTime Debug] Heartbeat $this (Focus)'"
			fi
			echo "set global wakatime_last_file '$kak_buffile'"
			echo "set global wakatime_last_beat $this"
			(eval "$command") < /dev/null > /dev/null 2> /dev/null &
		elif [ "$1" = "write" ]; then
			# The focused file was flushed, send an heartbeat.
			if [ "$kak_opt_wakatime_debug" = "true" ]; then
				echo "echo -debug '[WakaTime Debug] Heartbeat $this (Write)'"
			fi
			echo "set global wakatime_last_beat $this"
			(eval "$command --write") < /dev/null > /dev/null 2> /dev/null &
		elif [ $(($this - ${kak_opt_wakatime_last_beat:-0})) -gt $kak_opt_wakatime_beat_rate ]; then
			# The last heartbeat was long ago enough, we need to let WakaTime know we're still up.
			if [ "$knopk_opt_wakatime_debug" = "true" ]; then
				echo "echo -debug '[WakaTime Debug] Heartbeat $this (Timeout)'"
			fi
			echo "set global wakatime_last_beat $this"
			(eval "$command") < /dev/null > /dev/null 2> /dev/null &
		fi

	}
}

def -hidden	wakatime-init %{
	evaluate-commands %sh{
		undependency() {
			echo "echo -markup '{Error}WakaTime is not and could not be installed! Check the *debug* buffer.'"
			echo "echo -debug '[WakaTime] $1 not found, automatic installation failed.'"
			echo "echo -debug '[WakaTime] Restart Kakoune once this is remedied, or attempt to'"
			echo "echo -debug '[WakaTime] install the WakaTime CLI yourself.'"
			echo "echo -debug '[WakaTime] Try looking for it in your distribution\\'s packages.'"
			echo "echo -debug '[WakaTime] There\\'s also the \"wakatime\" package from PyPI.'"
			echo "echo -debug '[WakaTime] Otherwise, install it manually by downloading this archive:'"
			echo "echo -debug '[WakaTime] https://github.com/wakatime/wakatime/archive/master.zip'"
			echo "echo -debug '[WakaTime] and extract the contents of the wakatime-master directory there:'"
			echo "echo -debug '[WakaTime] $kak_opt_wakatime_plugin'"
			echo "echo -debug '[WakaTime] Once that\\'s done, you should be able to restart Kakoune and complete'"
			echo "echo -debug '[WakaTime] the installation.'"
			exit 1
		}

		# Is a WakaTime binary installed system-wide?
		command=""
		if [ -n "$(which wakatime 2> /dev/null)" ]; then
			# Don't bother downloading it.
			command="wakatime"
		elif [ -n "$(which wakatime-cli 2> /dev/null)" ]; then
			# Don't bother downloading it.
			command="wakatime-cli"
		else
			# We'll try to use a python version
			# Is Python installed?
			if [ -z "$(which python 2> /dev/null)" ]; then
				echo "echo -debug '[WakaTime] Error: Python isn\\'t installed, but is required to use WakaTime.'"
				echo "echo -markup '{Error}Python isn\\'t installed, but is required to use WakaTime.'"
				exit 1
			fi

			if [ -f "$kak_opt_wakatime_plugin/wakatime/cli.py" ]; then
				# It's not system-wide, but it's installed.
				command="python $kak_opt_wakatime_plugin/wakatime/cli.py"
			elif [ -w "$kak_opt_wakatime_plugin" ]; then
				# We should try to install it.
				echo "echo 'Installing WakaTime CLI...'"
				echo "echo -debug '[WakaTime] Installing CLI in the plugin\\'s directory: $kak_opt_wakatime_plugin.'"
				# We can't proceed without unzip or wget/curl
				if [ -z "$(which unzip 2> /dev/null)" ]; then
					undependency unzip
					exit 1
				elif [ -z "$(which wget 2> /dev/null)" ] && [ -z "$(which curl 2> /dev/null)" ]; then
					undependency "wget or curl"
					exit 1
				else
					url="https://github.com/wakatime/wakatime/archive/master.zip"
					zip=$(mktemp --tmpdir "wakatime.kak-XXXXXXXXXX")
					# We assume wget, but we'll prefer curl over it anytime.
					download="wget -q $url -O $zip"
					if [ -n "$(which curl 2> /dev/null)" ]; then
						download="curl -LSs --output $zip $url"
					fi

					($download &&
					unzip $zip -d $kak_opt_wakatime_plugin &&
					mv $kak_opt_wakatime_plugin/wakatime-master/wakatime $kak_opt_wakatime_plugin &&
					rm -rf $kak_opt_wakatime_plugin/wakatime-master &&
					rm -f $zip || exit 1) < /dev/null > /dev/null 2> /dev/null &
					command="python $kak_opt_wakatime_plugin/wakatime/cli.py"
				fi
			else
				# We're system-wide, alas the CLI is not.
				echo "echo -markup '{Error}WakaTime is not installed! Check the *debug* buffer.'"
				echo "echo -debug '[WakaTime] kakoune-wakatime is installed in a non-writable location,'"
				echo "echo -debug '[WakaTime] most likely the system autoload directory.'"
				echo "echo -debug '[WakaTime] You may either install WakaTime CLI yourself, via pip,'"
				echo "echo -debug '[WakaTime] or your system\'s package manager. The binary must be in your path.'"
				echo "echo -debug '[WakaTime] However, in the event this would be impossible, you will have'"
				echo "echo -debug '[WakaTime] to install WakaTime in your own autoload directory, which should'"
				echo "echo -debug '[WakaTime] be writeable. Do make sure that you have wget and unzip installed'"
				echo "echo -debug '[WakaTime] should you choose to go that way. Restart Kakoune after installing'"
				echo "echo -debug '[WakaTime] WakaTime or putting the plugin in a writeable location.'"
				echo "echo -debug '[WakaTime] We are sorry for the inconvenience.'"
				echo "echo -debug '[WakaTime] If you know what you are doing, you may install WakaTime in'"
				echo "echo -debug '[WakaTime] $kak_opt_wakatime_plugin'"
				echo "echo -debug '[WakaTime] with the following archive:'"
				echo "echo -debug '[WakaTime] https://github.com/wakatime/wakatime/archive/master.zip'"
				echo "echo -debug '[WakaTime] Do note, however, that if you can accomplish this, you should'"
				echo "echo -debug '[WakaTime] probably install a system or Python package instead.'"
				exit 1
			fi
		fi
		echo "echo -debug '[WakaTime] Ready. Heartbeats will be sent with $command.'"
		command="$command --plugin \"kakoune/$kak_version kakoune-wakatime/$kak_opt_wakatime_version\""
		if [ -n "$kak_opt_wakatime_file" ]; then
			command="$command --config $kak_opt_wakatime_file"
		fi
		echo "set global wakatime_command '$command'"
		echo "hook -group WakaTime global InsertKey .* %{ wakatime-heartbeat }"
		echo "hook -group WakaTime global ModeChange push:.*:insert %{ wakatime-heartbeat }"
		echo "hook -group WakaTime global BufWritePost .* %{ wakatime-heartbeat write }"
		echo "hook -group WakaTime global BufCreate .* %{ wakatime-heartbeat }"
		if ! eval "$command $kak_opt_wakatime_options --config-read api_key" 2> /dev/null >/dev/null; then
			echo "hook -group WakaTimeConfig global WinDisplay .* %{ wakatime-create-config }"
		fi
	}
}

hook -group WakaTime global KakBegin .* %{ wakatime-init }
