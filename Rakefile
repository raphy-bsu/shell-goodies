desc 'Generate Yardoc documentation for this project' # {{{
task :doc do |t|
  puts `yardoc graph --private --protected --title "Shell goodies" --readme README.md -o doc/  *.rb script/**/*.bash - AUTHORS.md COPYING.md MAINTAINERS.md`
end # }}}
