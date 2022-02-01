#!/usr/bin/env bash
REPO_ROOT=$(cd "$(dirname "$0")/../.."; pwd)

base_branch="$(git rev-parse --abbrev-ref HEAD)"
if [[ "$base_branch" != "master" ]]; then
  echo 'Aborting script, base branch should be master';
  exit 1;
fi
merge_branch="merge_release"
release_branch="release"

git config --global user.name "Shapr3D Dev"
git config --global user.email "dev@shapr3d.com"

git checkout -b "$merge_branch"
git merge "origin/$release_branch"

# if there are conflicts
if [[ "$(git status --porcelain --ignore-submodules)" != "" ]]; then
    echo "conflicts!!!!"
    git add .
    git merge --continue
fi

git push -f origin HEAD:"$merge_branch"

# Open new PR
curl -s -S -H "Authorization: token $GITHUB_TOKEN" --data "{\
    \"title\":\"L10n - update\",\
    \"base\":\"$base_branch\",\
    \"head\":\"$merge_branch\"\
}" https://api.github.com/repos/tibiiii/playground/pulls > /dev/null
