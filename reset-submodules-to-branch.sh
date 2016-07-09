#!/bin/bash
set -e

function usage {
    echo "USAGE: $0 [branch] [parent-repo-path] [reset-to-branch]" \
          "[modules-to-exclude-from-reset]"
    echo -e "\t [modules-to-exclude-from-reset] - should be enclosed in" \
          "parentheses and separeted by space\n"
    echo "Example: $0 mybranch ~/git/reponame master \"mysql" \
          "filebeat\""
}

if [ $# = 4 ];
then
    BRANCH=$1
    REPO_PATH=$2
    RESET_TO=$3
    REPOS_OMMITED=$4
else
    usage
    exit 0
fi

TIMESTAMP=$(date +%Y%m%d%H%M)

echo "Selected branch: $BRANCH"
echo "Parent repo location: $REPO_PATH"

echo "---------------------------------------------------------------------"
echo "Updating parent repo to $BRANCH and making backup named $BRANCH-$TIMESTAMP"
(cd $REPO_PATH && git checkout $BRANCH && git reset --hard \
    origin/$BRANCH && git checkout -b $BRANCH-$TIMESTAMP && git submodule \
    update --init --recursive --force && git push origin $BRANCH-$TIMESTAMP)
(cd $REPO_PATH && git checkout $BRANCH && git reset --hard origin/$BRANCH)

echo "---------------------------------------------------------------------"
echo "Making backup of $BRANCH if it exists in each repo"
(cd $REPO_PATH && git submodule foreach "if git ls-remote --heads \
    | grep -q $BRANCH; then git checkout -b $BRANCH-$TIMESTAMP && echo git \
    push origin $BRANCH-$TIMESTAMP; fi")

echo "---------------------------------------------------------------------"
echo "resetting to $RESET_TO"
(cd $REPO_PATH && git submodule foreach "(

if [[ \"${REPOS_OMMITED[*]}\" =~ $path ]]
then
  git checkout $BRANCH
  git clean -n -ff -d
  git reset --hard origin/$BRANCH
else
  git checkout $RESET_TO
  git reset --hard origin/$RESET_TO
fi

clean=\$(git clean -n -ff -d| wc -l)
if [ \$clean -gt 0 ]
then
  read -p \"Would you like to delete untracked files (\$clean)? [Y]\" input
  if [ \"x\$input\" = 'xY' ]
  then
    git clean -ff -d
  fi
fi

echo '---------------------------------------------------------------------'
)|| true")

echo "Staging all changes and commiting them"
(cd $REPO_PATH && git add -u && git commit -m "Update parent repo to" \
    "master $TIMESTAMP" || echo -e "\nNothing to commit - is parent repo" \
    "already up to date?\n\n")

echo "---------------------------------------------------------------------"
echo "After checking everything is ok - execute below command:"
echo "git push origin $BRANCH"
