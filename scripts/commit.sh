#!/usr/bin/env bash
echo "Attempting to commmit files to Git..."
git config user.email "development@convincible.media"
git config user.name "Convincible"
git add ./source/content && git commit -m "Automated content update from DatoCMS edits"
git push
exit 0 # Return success even if Git did not commit, to allow build process to continue