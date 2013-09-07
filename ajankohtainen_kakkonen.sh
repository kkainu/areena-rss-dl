#!/bin/bash

# Episodes will be downloaded under this directory (In the subdirectory defined by SHOW)
BASEDIR=~/Desktop
# Name of the show
SHOW=AjankohtainenKakkonen
# RSS feed url for the show
URL='http://areena.yle.fi/api/search.rss?id=1791995&media=video&sisalto=ohjelmat'

#################################################################################
#
#	Don't touch these
#
#################################################################################
SCRIPT_DIR=$( cd $(dirname $0) ; pwd -P)
SCRIPT="$SCRIPT_DIR/$(basename $0)"
source "$SCRIPT_DIR/yle-areena-dl.sh"
