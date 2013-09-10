#!/bin/bash

BASE_DIR=~/Desktop/Areena

#################################################################################
#
#	Don't touch these
#
#################################################################################

YLE_DL=/Applications/Areena-lataaja.app/Contents/Resources/yle-dl
SCRIPT_DIR=$( cd $(dirname $0) ; pwd -P)
SCRIPT_FILE=$SCRIPT_DIR/$(basename $0)
LAUNCH_CTL=com.areena-dl
LAUNCH_CTL_FILE=~/Library/LaunchAgents/$LAUNCH_CTL.plist
SHOWS_DIR=$SCRIPT_DIR/shows
DOWNLOADED_FILE=$BASE_DIR/downloaded.txt
LOG_FILE=$BASE_DIR/areena-dl.log

function install {
	if [ ! -f $LAUNCH_CTL_FILE ]; then
		cat <<- EOF > $LAUNCH_CTL_FILE
		<?xml version="1.0" encoding="UTF-8"?>
		<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
		<plist version="1.0">
		<dict>
		    <key>Label</key>
		    <string>$LAUNCH_CTL</string>
		    <key>ProgramArguments</key>
		    <array>
		        <string>$SCRIPT_FILE</string>
		    </array>
		    <key>StartInterval</key>
		    <integer>3600</integer>
		</dict>
		</plist>
		EOF
		echo "created $LAUNCH_CTL_FILE"
		launchctl load $LAUNCH_CTL_FILE
		echo "new episodes will be searched and downloaded automatically every hour"
	else
		echo "$LAUNCH_CTL_FILE already exists."
	fi
}

function uninstall {
	launchctl remove $LAUNCH_CTL
	rm $LAUNCH_CTL_FILE
}

function addshow {
	title=$(curl --silent "$1" | grep -m 1 -o 'CDATA\[.*\]' | sed 's/.*\[\(.*\)\]\]/\1/')
	script="$(sed 's/ /_/' <<< $title).sh"

	cat <<- EOF > "$SHOWS_DIR/$script"
		#!/bin/bash

		SHOW="$title"
		URL="$1"
	EOF
	chmod u+x "$SHOWS_DIR/$script"
}

function run {
	if [ ! -f "$BASE_DIR" ]; then
		mkdir -p "$BASE_DIR"
	fi

	if [ ! -f "$DOWNLOADED_FILE" ]; then
		touch "$DOWNLOADED_FILE"
	fi

	for show in $(ls $SHOWS_DIR/*.sh)
	do
		source "$show"
		
		if [ ! -f "$BASE_DIR" ]; then
			mkdir -p "$BASE_DIR/$SHOW"
		fi

		echo "$(date): checking for new episodes of $SHOW" >> "$LOG_FILE"
		urls=$(curl --silent $URL | grep -o '<link>.*</link>' | sed 's|<link>\(.*\)</link>|\1|g' | grep '[0-9]$')
		for url in $urls
		do
			if ! grep --quiet $url $DOWNLOADED_FILE; then
		  		echo "$(date): downloading $url" >> "$LOG_FILE"
		  		$YLE_DL/yle-dl --rtmpdump $YLE_DL/rtmpdump --destdir "$BASE_DIR/$SHOW" $url
		  		if [ $? -eq 0 ]; then
	    			echo $url >> "$DOWNLOADED_FILE"
				else
	    			echo "$(date): $url download failed" >> "$LOG_FILE"
				fi
			fi
		done
	done

	echo "$(date): done." >> "$LOG_FILE"
}

function usage {
	cat <<-ENDOFMESSAGE

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