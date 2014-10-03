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
end

check_binaries
copy_scripts
puts script_list
