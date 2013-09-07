#!/bin/bash

#################################################################################
#
#	Don't touch these
#
#################################################################################

YLE_DL=/Applications/Areena-lataaja.app/Contents/Resources/yle-dl
SHOW_DIR=$BASEDIR/$SHOW
DOWNLOADED_FILE=$SHOW_DIR/downloaded.txt
LOG_PREFIX="[AREENA-DOWNLOAD : $SHOW] "
LAUNCH_CTL_FILE=~/Library/LaunchAgents/areena.$SHOW.plist

if [ ! -f $SHOW_DIR ]; then
	mkdir -p $SHOW_DIR
fi

if [ ! -f $LAUNCH_CTL_FILE ]; then
cat << EOF > $LAUNCH_CTL_FILE
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

launchctl load $LAUNCH_CTL_FILE
touch $DOWNLOADED_FILE

echo "$LOG_PREFIX $SHOW - new episodes will be searched and downloaded automatically every hour"

return
fi

urls=$(curl --silent $URL | grep -o '<link>.*</link>' | sed 's|<link>\(.*\)</link>|\1|g' | grep '[0-9]$')

for url in $urls
do
	if grep --quiet $url $DOWNLOADED_FILE; then
  		echo "$LOG_PREFIX $url already downloaded" | logger
	else
  		echo "$LOG_PREFIX downloading $url" | logger
  		$YLE_DL/yle-dl --rtmpdump $YLE_DL/rtmpdump --destdir "$SHOW_DIR" $url
		echo $url >> $DOWNLOADED_FILE
	fi
done