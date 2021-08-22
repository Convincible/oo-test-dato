#!/usr/bin/env bash
echo "Dato dumped succesfully; will attempt to commmit files to Git..."
git add ./source/content && git commit -m "Automated content update from DatoCMS edits"
exit 0 # Return success even if Git did not commit, to allow build process to continue