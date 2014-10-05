#!/usr/bin/env ruby
# coding: utf-8

require 'fileutils'
require 'open3'

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

CONFIG_FILENAME = File.expand_path('~/.goodies-plugins')
INSTALL_DIR     = File.expand_path('~/.shell-goodies')
BINARY_PATH     = '/usr/bin/goodies'
# What file should be patched
BASHRC_PATH     = File.expand_path('~/.bashrc')
PLUGINS_DIR     = File.join(INSTALL_DIR, 'plugins')

# Try to execute block. If block raises ddxception, it puts bactrace and returns specified value.
#
# @param      [Hash]      options       Hash with options
# @param      [Proc]      block         Hash with options
#
# @option     options    [String]       :puts         Message to puts by logger
# @option     options    [Object]       :and_return   Object to return if block fails
# @option     options    [True,False]   :quite        Do not show backtrace
# @option     options    [Proc]         :finalize     Method to call if something goes wrong
#
# @return     Returs `nil` or specified value
def handle_errors options = {}, &block
  begin
    yield
  rescue Exception => e
    name = caller[1][/`.*'/][1..-2]
    defaults = {puts: "#{name} failed. See backtrace:", and_return: nil, call: nil}
    opts = defaults.merge options
    if @logger
      @logger.message :error, "#{opts[:puts]}"
    else
      puts "#{opts[:puts]}".on_red
    end
    unless opts[:quite]
      p e
      puts e.backtrace
    end
    opts[:call].call if opts[:call].kind_of? Proc
    opts[:and_return]
  end
end

# Execute shell command without output
#
# @return   [String]    Result of command execution
def sh command, sleep_interval = nil, attempts = 3
  # success=%x(#{command} 1> /dev/null)
  success = Open3.popen3("#{command}") do |stdin, stdout, stderr, wait_thr|
    wait_thr.value.success?
  end
  if attempts > 1
    unless success
      sleep sleep_interval if sleep_interval
      sh command, sleep_interval, attempts-1
    end
  else
    raise RuntimeError, "Failed to execute [ #{command} ]" unless success
  end
end

# Look up aptopriate binaries before install
# and raise SystemExit if some of binaries are missing
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

# Get list of available built-in scripts
#
# @return   [Array]   the list of file basenames
def script_list
  Dir['script/*'].map{|f| File.basename(f, ".*")}
end

# Get list of available plugins
#
# @return   [Array]   the list of file basenames
def plugins_links
  if File.exists? CONFIG_FILENAME
    File.readlines(CONFIG_FILENAME).uniq
  else
    []
  end
end

# Download plugins in
def download_plugins
  def name_for(plugin)
    plugin.split('/').last.strip
  end

  plugins_links.map(&:strip).each do |link|
    handle_errors quite: true, puts: "Could not load plugin from #{link}" do
      copy_path = File.join(PLUGINS_DIR, "#{name_for(link)}")

      sh "rm -rf #{PLUGINS_DIR}/*"
      FileUtils.mkdir_p copy_path

      puts "Fetching plugin #{name_for(link)}".bold
      sh "git clone #{link} #{copy_path}"
      puts "Installed #{name_for(link).bold} from #{link.underline}"
    end
  end
end

# Install plugins to your home directory
def install_plugins
  download_plugins
end

# Copy scripts to home folder
def copy_scripts
  script_list.each do |name|
    source = File.join(__dir__, "script/#{name}.bash")
    dest = File.expand_path("~/.#{name}-goodies.bash")
    puts "Copy #{name}-goodies".green
    `cp #{source} #{dest}`
  end
end

# Add scripts to .bashrc
def patch_bashrc
  bashrc = File.readlines(BASHRC_PATH)
  script_list.each do |name|
    require_line = "source ~/.#{name}-goodies.bash"
    unless bashrc.any?{|l| l =~ /#{require_line}/ }
      puts "Install #{name}-goodies in ~/.bashrc"
      open(BASHRC_PATH, 'a') { |f| f.puts require_line }
    else
      puts "#{name}-goodies already in ~/.bashrc"
    end
  end
end

def create_symlink
  unless !File.symlink?(BINARY_PATH) ||  __FILE__ == BINARY_PATH
    file = File.expand_path(__FILE__, __dir__)
    `sudo ln -s -f #{file} #{BINARY_PATH}`
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
  install_plugins
  puts "Done!".green
when 'update'
  update
else
  puts "Only `install` or `update` commands are supported.".yellow
end
