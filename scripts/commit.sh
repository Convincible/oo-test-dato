#!/usr/bin/env bash
echo "Attempting to commmit files to Git..."

echo "CURRENT WORKING DIRECTORY"
pwd
echo "DIRECTORY LISTING"
ls -la
echo "GIT CONFIG"
git config -l
echo "GIT REMOTE"
git remote -v
echo "GIT STATUS"
git status

echo "ADD ORIGIN"
git remote add origin git@github.com:Convincible/oo-test-dato.git

echo "CONFIGURE GIT"
git config user.email "development@convincible.media"
git config user.name "Convincible"

echo "COMMIT"
git add ./source/content && git commit -m "Automated content update from DatoCMS edits"
echo "PUSH"
git push origin HEAD:master
echo "DONE"
exit 0 # Return success even if Git did not commit, to allow build process to continue