#!/bin/bash

# Check if DiffMerge already installed
if [ ! -d "/Applications/DiffMerge.app" ]; then
	echo "Download and install DiffMerge"
	curl -O http://download.sourcegear.com/DiffMerge/4.2.1/DiffMerge.4.2.1.1013.intel.stable.dmg
	sudo hdiutil attach DiffMerge.4.2.1.1013.intel.stable.dmg
	cp -r /Volumes/DiffMerge\ 4.2.1.1013\ intel\ stable/DiffMerge.app /Applications
	cp /Volumes/DiffMerge\ 4.2.1.1013\ intel\ stable/Extras/diffmerge.sh /usr/local/bin
	chmod a+x /usr/local/bin/diffmerge.sh
	ln -s /usr/local/bin/diffmerge.sh /usr/local/bin/diffmerge
	hdiutil eject /Volumes/DiffMerge\ 4.2.1.1013\ intel\ stable
	rm DiffMerge.4.2.1.1013.intel.stable.dmg
fi

echo "Setting up DiffMerge tool in git"
git config --global diff.tool diffmerge
git config --global difftool.diffmerge.cmd '/usr/local/bin/diffmerge "$LOCAL" "$REMOTE"'
git config --global merge.tool diffmerge
git config --global mergetool.diffmerge.trustExitCode true
git config --global mergetool.diffmerge.cmd '/usr/local/bin/diffmerge -result="$MERGED" "$LOCAL" "$BASE" "$REMOTE"'

echo "Setting up Kaleidoscope"
# curl -sSL -k https://updates.blackpixel.com/latest\?app\=ksdiff\&v\=122 -o ksdiff-122-2.2.0.zip
# unzip ksdiff-122-2.2.0.zip

git config --global diff.tool 'Kaleidoscope'
git config --global merge.tool 'Kaleidoscope'
git config --global mergetool.Kaleidoscope.cmd 'ksdiff --merge --output "$MERGED" --base "$BASE" -- "$LOCAL" --snapshot "$REMOTE" --snapshot'
git config --global mergetool.Kaleidoscope.trustexitcode truek
git config --global difftool.Kaleidoscope.cmd 'ksdiff --partial-changeset --relative-path "$MERGED" -- "$LOCAL" "$REMOTE"'
git config --global difftool.prompt false
git config --global mergetool.prompt false


echo "Setting up author"
git config --global user.name "Jim Wallace"
git config --global user.email "jim@extroverteddeveloper.com"

git config --global pager.branch false
