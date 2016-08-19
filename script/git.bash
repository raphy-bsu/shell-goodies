#!/usr/bin/env bash

function update_repo(){
  git remote update
  git pull --all
}

function current_branch(){
  git rev-parse --abbrev-ref HEAD
}

function current_issue(){
  echo `current_branch` | awk -F_ '{print $1}' | grep -o '[0-9]\+'
}

function gp(){
  echo "PUSH to $(current_branch)"
  git push origin `current_branch`
}


function commit(){
  if [[ $1 ]]; then
    issue=`current_issue`
    if [[ ${issue} ]]; then
      git commit -m "#$issue - $1"
    else
      echo "No issue detected. General commit"
      git commit -m "$1"
    fi
  else
    echo "Specify message for commit"
  fi
}

function git_clean_merged_branches(){
  git branch --merged | grep -v "\*" | xargs -n 1 git branch -d
}
