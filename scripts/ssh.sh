#!/usr/bin/env bash
echo "Adding SSH from Environment Variables"

# Check if we're running in a Netlify environment
# See https://www.netlify.com/docs/continuous-deployment/#environment-variables
#if [ "$NETLIFY" = "true" ]
#then
	dir=~/.ssh

    # Init .ssh dir and expand $SSH_KEY
    mkdir -p "$dir"
    echo -e "-----BEGIN OPENSSH PRIVATE KEY-----\\n${DEPLOY_KEY//_/\\n}\\n-----END OPENSSH PRIVATE KEY-----" >> "$dir/${SITE_ID}"
    chmod og-rwx "$dir/${SITE_ID}"

    # Uncomment to debug
    #ls -la "$dir"
    #cat "$dir/${SITE_ID}"

    # Add host keys, comment out if not needed
    #ssh-keyscan -H github.com >> ~/.ssh/known_hosts
#fi