#!/usr/bin/env ruby
# coding: utf-8

begin
  require 'colorize'
rescue Exception
  puts "Installing appropriate gems"
  `sudo gem install colorize`
  `gem install colorize`
  Gem.refresh
  require 'colorize'
end

BINARIES = [
  "git",
  "hub",
  "bundle",
]

def check_binaries
  all_installed = true
  BINARIES.each do |bin|
    if `which #{bin}`.empty?
      all_installed = false
      puts "#{bin} "+"[NOT FOUND]".red
    else
      puts "#{bin} "+"[OK]".green
    end
  end

  unless all_installed
    puts "Install appropriate programs before"
    raise SystemExit
  end

end

def script_list
  Dir['script/*'].map{|f| File.basename(f, ".*")}
end

def copy_scripts
  script_list.each do |name|
    source = File.join(__dir__, "script/#{name}.bash")
    dest = File.expand_path("~/.#{name}-goodies.bash")
    puts "Copy #{name}-goodies".green
    `cp #{source} #{dest}`
  end
end

def patch_bashrc
  bashrc_path = File.expand_path('~/.bashrc')
  bashrc = File.readlines(bashrc_path)
  script_list.each do |name|
    require_line = "source ~/.#{name}-goodies.bash"
    unless bashrc.any?{|l| l =~ /#{require_line}/ }
      puts "Install #{name}-goodies in ~/.bashrc"
      open(bashrc_path, 'a') { |f| f.puts require_line }
    else
      puts "#{name}-goodies already in ~/.bashrc"
    end
  end
end

def create_symlink
  unless !File.symlink?('/usr/bin/goodies') ||  __FILE__ == '/usr/bin/goodies'
    file = File.expand_path(__FILE__, __dir__)
    `sudo ln -s -f #{file} /usr/bin/goodies`
    puts "Create binary".green
  else
    puts 'Binary exists'
  end
end

def update
  `cd #{__dir__} && git pull origin master`
  install
end

def install
  check_binaries
  copy_scripts
  patch_bashrc
  create_symlink
end

case ARGV.first
when 'install'
  install
when 'update'
  update
else
  puts "Only `install` or `update` commands are supported.".yellow
end
