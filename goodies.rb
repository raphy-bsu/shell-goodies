#!/usr/bin/env ruby
# coding: utf-8

require 'fileutils'
require 'open3'

class GemNotFound < Exception; end

begin
  raise GemNotFound unless system("gem which bundler")
  require 'colorize'
  require 'os'
rescue Exception
  puts 'Installing appropriate gems'
  if `which gem`.include? '/usr/'
    puts "We need your password to install gems widesystem"
    `sudo gem install colorize`
    `sudo gem install os`
    `sudo gem install bundler` unless system("gem which bundler")
  else
    `gem install colorize`
    `gem install os`
    `gem install bundler` unless system("gem which bundler")
  end
  Gem.refresh
  require 'colorize'
  require 'os'
end

BINARIES = %w(git bundle)

CONFIG_FILENAME = File.expand_path('~/.goodies-plugins')
INSTALL_DIR     = File.expand_path('~/.shell-goodies')
BINARY_PATH     = '/usr/bin/goodies'
# What file should be patched
BASHRC_PATH     = OS.mac? ? File.expand_path('~/.bash_profile') : File.expand_path('~/.bashrc')
PLUGINS_DIR     = File.join(INSTALL_DIR, 'plugins')
GOODIES_INCLUDES_PATH = File.expand_path('~/.goodies-sources')

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
      puts "#{bin} "+'[NOT FOUND]'.red
    else
      puts "#{bin} "+'[OK]'.green
    end
  end

  unless all_installed
    puts 'Install appropriate programs before'
    raise SystemExit
  end

end

# Get list of available built-in scripts
#
# @return   [Array]   the list of file basenames
def script_list
  Dir['script/*'].map{|f| File.basename(f, '.*')}
end

# Get list of available plugins
#
# @return   [Array]   the list of file basenames
def plugins_links
  if File.exists? CONFIG_FILENAME
    File.readlines(CONFIG_FILENAME).reject{|l| l =~ /^[ ]*[#].*$/ }.uniq
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


def generate_goodies_includes
  built_in = Dir['script/*'].map{|f| File.expand_path f}
  plugins  = Dir["#{PLUGINS_DIR}/**/*.bash"].map{|f| File.expand_path f}
  open(GOODIES_INCLUDES_PATH, 'w') do |f|
    (built_in+plugins).map{|p| "source #{p}"}.each do |source|
      f.puts source
    end
  end
  puts 'Generate goodies includes'.green
end

# Install plugins to your home directory
def install_plugins
  download_plugins
  generate_goodies_includes
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
  require_line = 'source ~/.goodies-sources'
  if bashrc.any? { |l| l =~ /#{require_line}/ }
    puts 'goodies-sources already in your bash config'
  else
    puts 'Install goodies-sources in your bash config'
    open(BASHRC_PATH, 'a') { |f| f.puts require_line }
  end
end

def create_symlink
  if !File.symlink?(BINARY_PATH) || __FILE__ == BINARY_PATH
    puts 'Binary exists'
  else
    file = File.expand_path(__FILE__, __dir__)
    `sudo ln -f #{file} #{BINARY_PATH}`
    puts 'Create binary'.green
  end
end

# Update current installation of goodies.rb
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
  puts 'Done!'.green
when 'update'
  update
  install_plugins
else
  puts 'Only `install` or `update` commands are supported.'.yellow
end
