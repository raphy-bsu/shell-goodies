function deploy(){
  git push origin master
  bundle exec cap production deploy
}

function spec(){
  bundle exec rspec spec/
}

function best(){
  rails_best_practices -f html .
}


alias rc='bin/rails c'
alias rs='bin/rails s'
alias st='git st'
