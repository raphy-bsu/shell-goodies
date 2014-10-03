function update_repo(){
  git remote update
  git pull --all
}

function current_branch(){
  git rev-parse --abbrev-ref HEAD
}

function current_issue(){
  echo `current_branch` | grep -o '[0-9]\+'
}

function pull_request(){
  if [[ -n $(current_issue) ]]; then
    hub pull-request -i `current_issue`
  else
    echo "Can not fetch issue number, make sure you are on valid branch"
  fi
}

function gp(){
  echo "PUSH to $(current_branch)"
  git push origin `current_branch`
}

