git remote add upstream https://github.com/zendesk/zendesk_api_client_rb
git fetch upstream
git fetch origin
git pull origin master
git rebase --onto upstream/master HEAD~3
git push -f origin master
