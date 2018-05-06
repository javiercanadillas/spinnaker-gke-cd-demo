#!/bin/bash -xe

# git config --global user.email "[EMAIL_ADDRESS]"
# git config --global user.name "[USERNAME]"

git init
git add .
git commit -m "Initial commit"

gcloud source repos create sample-app
git config credential.helper gcloud.sh

export PROJECT=$(gcloud info --format='value(config.project)')
git remote add origin https://source.developers.google.com/p/$PROJECT/r/sample-app

git push origin master
