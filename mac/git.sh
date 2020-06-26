echo "Download and install DiffMerge"
curl -O http://download.sourcegear.com/DiffMerge/4.2.1/DiffMerge.4.2.1.1013.intel.stable.dmg
sudo hdiutil attach DiffMerge.4.2.1.1013.intel.stable.dmg
cp -r /Volumes/DiffMerge\ 4.2.1.1013\ intel\ stable/DiffMerge.app /Applications
cp /Volumes/DiffMerge\ 4.2.1.1013\ intel\ stable/Extras/diffmerge.sh /usr/local/bin
chmod a+x /usr/local/bin/diffmerge.sh
ln -s /usr/local/bin/diffmerge.sh /usr/local/bin/diffmerge
hdiutil eject /Volumes/DiffMerge\ 4.2.1.1013\ intel\ stable
rm DiffMerge.4.2.1.1013.intel.stable.dmg

echo "Setting up DiffMerge tool in git"
git config --global diff.tool diffmerge
git config --global difftool.diffmerge.cmd '/usr/local/bin/diffmerge "$LOCAL" "$REMOTE"'
git config --global merge.tool diffmerge
git config --global mergetool.diffmerge.trustExitCode true
git config --global mergetool.diffmerge.cmd '/usr/local/bin/diffmerge -result="$MERGED" "$LOCAL" "$BASE" "$REMOTE"'

