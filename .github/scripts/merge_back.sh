#!/usr/bin/env bash
REPO_ROOT=$(cd "$(dirname "$0")/../.."; pwd)

base_branch="$(git rev-parse --abbrev-ref HEAD)"
if [[ "$base_branch" != "master" ]]; then
  echo 'Aborting script, base branch should be master';
  exit 1
fi
merge_branch="merge_release"
release_branch="release"

git config --global user.name "Shapr3D Dev"
git config --global user.email "dev@shapr3d.com"

if git show-branch "origin/$merge_branch" &>/dev/null; then
    # if a `merge_branch` already exists
    # 1. check if merge without conflict is possible for `master` and `release`
    #    if yes, do the merge and push
    #    if no, abort, merge resolution has to be done manually

    echo "Previous \"$merge_branch\" already exists"
    git checkout "$merge_branch"

    function merge_branch_if_possible () {
        echo "::group::Merge branch \"$1\""

        git merge --no-commit --no-ff "$1"
        if git diff --diff-filter=U --check --exit-code; then
            echo "Can merge \"$1\""
            git commit --all --no-edit
            git push origin HEAD:"$merge_branch"
        else
            echo "Can't merge \"$1\", there are conflicts to resolve."
            git merge --abort
        fi
        echo "::endgroup::"
    }

    merge_branch_if_possible $base_branch
    merge_branch_if_possible $release_branch
else
    # if no `merge_branch`
    # 1. checkout `release`
    # 2. create new `merge_branch` from `release`
    # 3. open a PR `merge_branch` -> `master`
    echo "No previous \"$merge_branch\""

    git checkout "$release_branch"
    git checkout -b "$merge_branch"
    git push -f origin HEAD:"$merge_branch"

    # Open new PR
    curl -s -S -H "Authorization: token $GITHUB_TOKEN" --data "{\
        \"title\":\"L10n - update\",\
        \"base\":\"$base_branch\",\
        \"head\":\"$merge_branch\"\
    }" https://api.github.com/repos/tibiiii/playground/pulls > /dev/null
fi
