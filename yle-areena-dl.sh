#!/bin/bash

downloads_root_dir=~/Desktop/Areena

#################################################################################
#
#	Don't touch these
#
#################################################################################

script_dir=$( cd $(dirname $0) ; pwd -P)
script_file=$script_dir/$(basename $0)
bin_dir=$script_dir/bin
launch_ctl=com.areena-dl
launch_ctl_file=~/Library/LaunchAgents/$launch_ctl.plist
shows_dir=$script_dir/shows
downloaded_file=$script_dir/run/downloaded.txt
log_file=$script_dir/logs/areena-dl.log

function install {
	if [ ! -f $launch_ctl_file ]; then
		cat <<- EOF > $launch_ctl_file
		<?xml version="1.0" encoding="UTF-8"?>
		<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
		<plist version="1.0">
		<dict>
		    <key>Label</key>
		    <string>$launch_ctl</string>
		    <key>ProgramArguments</key>
		    <array>
		        <string>$script_file</string>
		    </array>
		    <key>StartInterval</key>
		    <integer>3600</integer>
		</dict>
		</plist>
		EOF
		echo "created $launch_ctl_file"
		launchctl load $launch_ctl_file
		echo "new episodes will be searched and downloaded automatically every hour"
	else
		echo "$launch_ctl_file already exists."
	fi
}

function uninstall {
	launchctl remove $launch_ctl
	rm $launch_ctl_file
}

function addshow {
	title=$(curl --silent "$1" | grep -m 1 -o 'CDATA\[.*\]' | sed 's/.*\[\(.*\)\]\]/\1/')
	script="$(sed 's/ /_/' <<< $title).sh"

	cat <<- EOF > "$shows_dir/$script"
		#!/bin/bash

		SHOW="$title"
		URL="$1"
	EOF
	chmod u+x "$shows_dir/$script"
}

function run {

	if [ ! -f "$script_dir/logs" ]; then
		mkdir -p "$script_dir/logs"
		touch $downloaded_file
	fi

	if [ ! -f "$script_dir/run" ]; then
		mkdir -p "$script_dir/run"
	fi

	for show in $shows_dir/*.sh
	do
		source "$show"
		
		if [ ! -f "$downloads_root_dir" ]; then
			mkdir -p "$downloads_root_dir/$SHOW"
		fi

		echo "$(date): checking for new episodes of $SHOW" >> "$log_file"
		urls=$(curl --silent $URL | grep -o '<link>.*</link>' | sed 's|<link>\(.*\)</link>|\1|g' | grep '[0-9]$')
		for url in $urls
		do
			if ! grep --quiet $url $downloaded_file; then
		  		echo "$(date): downloading $url" >> "$log_file"
		  		$bin_dir/yle-dl --rtmpdump $bin_dir/rtmpdump --quiet --destdir "$downloads_root_dir/$SHOW" $url
		  		if [ $? -eq 0 ]; then
	    			echo $url >> "$downloaded_file"
				else
	    			echo "$(date): $url download failed" >> "$log_file"
				fi
			fi
		done
	done

	echo "$(date): done." >> "$log_file"
}

function usage {
	cat <<- ENDOFMESSAGE

	Usage: $(basename "$0") [-i|-u|-h|-a rss_url]

	where
	-i              installs the periodically running new episode checker
	-u              uninstalls the episode checker
	-a rss_url      adds a new show using the show's rss feed url (rss url can be found from the show's page in areena.yle.fi)
	-h              prints this message

	ENDOFMESSAGE
}

if [ "$#" == "0" ]; then
    run
    exit 0
fi

case "$1" in
    -i | --install)
		install
		;;
    -u | --uninstall)
    	uninstall
		;;
	-a | --addshow)
		if [ "$#" -lt "2" ]; then
    		usage
    		exit 0
		fi
		addshow "$2"
		;;
    -h | --help)
    	usage
		;;
	*) 
		usage
   		;;
esac