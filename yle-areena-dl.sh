#!/bin/bash

#################################################################################
#
#	Don't touch these
#
#################################################################################

YLE_DL=/Applications/Areena-lataaja.app/Contents/Resources/yle-dl
SHOW_DIR=$BASEDIR/$SHOW
DOWNLOADED_FILE=$SHOW_DIR/downloaded.txt
LAUNCH_CTL=areena.$SHOW
LAUNCH_CTL_FILE=~/Library/LaunchAgents/$LAUNCH_CTL.plist
LOG_FILE=$SHOW_DIR/areena-dl.log

function install {
	if [ ! -f $LAUNCH_CTL_FILE ]; then
		cat <<- EOF > $LAUNCH_CTL_FILE
		<?xml version="1.0" encoding="UTF-8"?>
		<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
		<plist version="1.0">
		<dict>
		    <key>Label</key>
		    <string>areena.$SHOW</string>
		    <key>ProgramArguments</key>
		    <array>
		        <string>$SCRIPT</string>
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

function run {
	if [ ! -f $SHOW_DIR ]; then
		mkdir -p $SHOW_DIR
	fi

	if [ ! -f $DOWNLOADED_FILE ]; then
		touch $DOWNLOADED_FILE
	fi
	
	urls=$(curl --silent $URL | grep -o '<link>.*</link>' | sed 's|<link>\(.*\)</link>|\1|g' | grep '[0-9]$')

	echo "$(date): checking for new episodes of $SHOW" >> $LOG_FILE

	for url in $urls
	do
		if grep --quiet $url $DOWNLOADED_FILE; then
	  		echo "$url already downloaded"
		else
	  		echo "$(date): downloading $url" >> $LOG_FILE
	  		$YLE_DL/yle-dl --rtmpdump $YLE_DL/rtmpdump --destdir "$SHOW_DIR" $url
	  		if [ $? -eq 0 ]; then
    			echo $url >> $DOWNLOADED_FILE
			else
    			echo "$(date): $url download failed" >> $LOG_FILE
			fi
		fi
	done

	echo "$(date): done." >> $LOG_FILE
}

function usage {
	cat <<-ENDOFMESSAGE

	Usage: $(basename "$0") [-i|-u|-h]

	where
	-i installs the periodically running new episode checker
	-u uninstalls the episode checker
	-h prints this message

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
    -h | --help)
    	usage
		;;
	*) 
		usage
   		;;
esac