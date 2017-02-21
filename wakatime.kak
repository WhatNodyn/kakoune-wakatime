# wakatime.kak version 3.0.0
# By Nodyn

decl str	wakatime_file		%sh{ printf "$HOME/.wakatime.cfg" }
decl str	wakatime_options

decl str	wakatime_version	"3.0.1"
decl str	wakatime_command
decl str	wakatime_plugin		%sh{ dirname "$kak_source" }

decl str	wakatime_beat_rate	120
decl str	wakatime_last_file
decl int	wakatime_last_beat

def -hidden	wakatime-create-config %{
	%sh{
		if [ -z "$(grep "api_key" $kak_opt_wakatime_file 2> /dev/null)" ]; then
			echo "prompt 'Enter your WakaTime API key: ' %{ %sh{
				echo \"[settings]\" > $kak_opt_wakatime_file
				echo \"debug = false\" >> $kak_opt_wakatime_file
				echo \"api_key = \$kak_text\" >> $kak_opt_wakatime_file
			} }"
		fi
	}
	rmhooks global WakaTimeConfig
}

def -hidden	wakatime-heartbeat -params 0..1 %{
	%sh{
		# First, if we're not in a real file, abort.
		if [ "$kak_buffile" == "$kak_bufname" ]; then
			exit
		fi

		# Still here? Let's get the current time.
		this=$(date "+%s")

		# Every command will look like that.
		command="$kak_opt_wakatime_command --entity \"$kak_buffile\" --time $this --plugin \"kakoune-wakatime/$wakatime_version\""

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
			echo "echo -debug '[WakaTime Debug] Heartbeat $this (Focus)'"
			echo "set global wakatime_last_file '$kak_buffile'"
			echo "set global wakatime_last_beat $this"
			(eval "$command") < /dev/null > /dev/null 2>&1 &
		elif [ "$1" == "write" ]; then
			# The focused file was flushed, send an heartbeat.
			echo "echo -debug '[WakaTime Debug] Heartbeat $this (Write)'"
			echo "set global wakatime_last_beat $this"
			(eval "$command --write") < /dev/null > /dev/null 2>&1 &
		elif (( $this - ${kak_opt_wakatime_last_beat:-0} >= $kak_opt_wakatime_beat_rate )); then
			# The last heartbeat was long ago enough, we need to let WakaTime know we're still up.
			echo "echo -debug '[WakaTime Debug] Heartbeat $this (Timeout)'"
			echo "set global wakatime_last_beat $this"
			(eval "$command") < /dev/null > /dev/null 2>&1 &
		fi

	}
}

def -hidden	wakatime-init %{
	%sh{
		# Is Python installed?
		if [ -z "$(which python 2> /dev/null)" ]; then
			echo "echo -debug '[WakaTime] Error: Python isn\\'t installed, but is required to use WakaTime.'"
			echo "echo -color Error 'Python isn\\'t installed, but is required to use WakaTime.'"
			exit 1
		fi

		# Is WakaTime installed system-wide?
		command=""
		if [ -n "$(which wakatime 2> /dev/null)" ]; then
			# Don't bother downloading it.
			command="wakatime"
		elif [ -f "$kak_opt_wakatime_plugin/wakatime/cli.py" ]; then
			# It's not system-wide, but it's installed.
			command="python $kak_opt_wakatime_plugin/wakatime/cli.py"
		else
			# We should try to install it.
			echo "echo 'Installing WakaTime CLI...'"
			echo "echo -debug '[WakaTime] Installing CLI in the plugin\\'s directory: $kak_opt_wakatime_plugin.'"
			if [ -n "$(which wget 2> /dev/null)" ] && [ -n "$(which unzip 2> /dev/null)" ]; then
				zip=$(mktemp --tmpdir "wakatime.kak-XXXXXXXXXX")
				(wget -q "https://github.com/wakatime/wakatime/archive/master.zip" -O $zip;
				unzip $zip -d $kak_opt_wakatime_plugin;
				mv $kak_opt_wakatime_plugin/wakatime-master/wakatime $kak_opt_wakatime_plugin;
				rm -rf $kak_opt_wakatime_plugin/wakatime-master;
				rm -f $zip) < /dev/null > /dev/null 2>&1 &
				command="python $kak_opt_wakatime_plugin/wakatime/cli.py"
			else
				echo "echo -color Error 'WakaTime is not and could not be installed! Check the *debug* buffer.'"
				echo "echo -debug '[WakaTime] wget or unzip not found, automatic installation failed.'"
				echo "echo -debug '[WakaTime] You may install these and restart Kakoune, or attempt to'"
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
			fi
		fi
		echo "echo -debug '[WakaTime] Ready. Heartbeats will be sent with $command.'"
		command="$command --config $kak_opt_wakatime_file --plugin \"wakatime.kak/$kak_opt_wakatime_version\""
		command="$command $kak_opt_wakatime_options"
		echo "set global wakatime_command '$command'"
		echo "hook -group WakaTime global InsertKey .* %{ wakatime-heartbeat }"
		echo "hook -group WakaTime global InsertBegin .* %{ wakatime-heartbeat }"
		echo "hook -group WakaTime global BufWritePost .* %{ wakatime-heartbeat write }"
		echo "hook -group WakaTime global BufCreate .* %{ wakatime-heartbeat }"
		# Prompting for the API key doesn't work. You can write the file yourself, use another WakaTime plugin
		# or pass it as an argument through the wakatime_options option.
		if [ ! -f "$kak_opt_wakatime_file" ]; then
			echo "hook -group WakaTimeConfig global BufCreate .* %{ wakatime-create-config }"
		fi
	}
}

hook -group WakaTime global KakBegin .* %{ wakatime-init }
