### A simple bash script for automatically downloading new episodes from Yle-Areena (OS X).

#### Prerequisites

- Install Areena lataaja from [here](http://users.tkk.fi/spotinka/areena/Areena-lataaja_10.8.dmg)
- Clone this repo: `git clone git@github.com:kkainu/osx-areena-dl.git`

#### Usage

1. To create a new episode to follow, make a copy from the example episode downloader _ajankohtainen_kakkonen.sh_
2. Edit the newly created file and replace _BASEDIR_ variable with a directory where the episodes should be downloaded.
3. Edit the SHOW variable and come up with a unique name for your series. All new episodes will be downloaded under the _BASEDIR/SHOW_ directory
4. Replace the URL variable with a RSS-feed Url for the series you want to follow. The url can be found from http://areena.yle.fi/ and searching for a show you want to follow. After searching copy the RSS-link.
5. Run the newly created script eg. _./pikku_kakkonen.sh -i_. This will create a new hourly running task which will download any new episodes to the previously defined directory

#### Uninstalling a downloader

1. Run _./pikku_kakkonen.sh -u_ 
