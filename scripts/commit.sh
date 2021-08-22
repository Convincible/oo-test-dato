#!/usr/bin/env bash
echo "Attempting to commmit files to Git..."

#!/usr/bin/env bash
echo "Adding SSH from Environment Variables"

# Check if we're running in a Netlify environment
# See https://www.netlify.com/docs/continuous-deployment/#environment-variables
#if [ "$NETLIFY" = "true" ]
#then
	dir=~/.ssh
	owner=Convincible
	repo=oo-test-dato

    # Init .ssh dir and expand $SSH_KEY
    mkdir -p "$dir"
    echo -e "-----BEGIN OPENSSH PRIVATE KEY-----\\n${DEPLOY_KEY//_/\\n}\\n-----END OPENSSH PRIVATE KEY-----" > "$dir/$repo"
    chmod og-rwx "$dir/$repo"

	# Turn on SSH agent
	eval `ssh-agent -s`
    ssh-add "$dir/$repo"

	# Update config with alias
	touch "$dir/config"
	chmod 600 "$dir/config"
	echo -e "Host github.com-$repo\\nHostname github.com\\nIdentityFile=$dir/$repo" >> "$dir/config"

    # Uncomment to debug
    #ls -la "$dir"
    #cat "$dir/$repo"

    # Add host keys, comment out if not needed
    #ssh-keyscan -H github.com >> ~/.ssh/known_hosts
#fi

echo "TEST SSH"
ssh -T git@github.com


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
git remote add origin "git@github.com-$repo:$owner/$repo.git"
git remote set-url origin "git@github.com-$repo:$owner/$repo.git"

echo "CONFIGURE GIT"
git config user.email "development@convincible.media"
git config user.name "Convincible"

echo "COMMIT"
git add ./source/content && git commit -m "Automated content update from DatoCMS edits"
echo "PUSH"
git push origin HEAD:master
echo "DONE"


exit 0 # Return success even if Git did not commit, to allow build process to continue