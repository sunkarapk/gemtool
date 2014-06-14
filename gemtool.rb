#!/usr/bin/ruby

GEMTOOL_VERSION = "1.0.0"

require 'optparse'

class String
  # Returns the color with given code
  def code(code)
    "\033[#{code.to_s}m#{self}\033[0m"
  end

  # Returns the string in red color
  def red
    self.code 31
  end

  # Returns the string in green color
  def green
    self.code 32
  end

  # Returns the string in yellow color
  def yellow
    self.code 33
  end

  # Return the string in bold
  def bold
    self.code 1
  end
end

def status
  print "#{($?.success? ? "[DONE]".green : "[FAIL]".red)}\n"
end

trap("SIGINT") do
  puts "\nShutdown signal sent. Quitting ...".red
  $stdout.flush
  sleep(2)
  exit
end

options = {}

opts = OptionParser.new do |p|
  p.banner = "Usage: gemtool [actions | [options] commands]\n\n  Commands:\n"

  p.on('-i', '--install FILE', "Install the gems from the given gem list") do |file|
    options[:command] = "install"
    options[:file] = file
  end

  p.on('-u', '--uninstall FILE', "Uninstall the gems from the given gem list") do |file|
    options[:command] = "uninstall"
    options[:file] = file
  end

  p.on('-t', '--update', "Updates all the outdated gems") do
    options[:command] = "update"
  end

  p.on('-p', '--prune', "Removes all the older versions of gems while keeping that latest intact") do
    options[:command] = "prune"
  end

  p.on('-c', '--clean FILE', "Make your gem list equal to given gem list\n\n  Actions:") do |file|
    options[:command] = "clean"
    options[:file] = file
  end

  p.on('-v', '--version', 'Version of gemtool') do
    puts "Gemtool version: #{GEMTOOL_VERSION}"
    exit
  end

  p.on('-h', '--help', "Display this screen\n\n  Options:") do
    puts p
    exit
  end

  options[:doc] = false
  p.on('-d', '--[no-]doc', "Install documentation (default false)") do |n|
    options[:doc] = n
  end

  options[:source] = nil
  p.on('-s', '--source URL', "Use URL as the remote source for gems") do |url|
    options[:source] = url
  end
end

begin
  opts.parse! ARGV
rescue OptionParser::MissingArgument
  puts opts
  exit
else
  if options[:command].nil?
    puts opts
    exit
  else
    gemopts = ""
    gemopts << " --no-rdoc --no-ri" unless options[:doc]
    gemopts << " --source #{options[:source]}" unless options[:source].nil?

    case options[:command]
      when "install"
        target = File.open(options[:file])

        while gem = target.gets
          gem =~ /(.+) \((.*)\)\n/
          name = $1
          versions = $2.split(', ')

          versions.each do |ver|
            print "Checking #{name}-#{ver} ".ljust(50)
            gem_installed  = `gem list #{name} -i -v #{ver} 2>/dev/null`

            if gem_installed.chomp == "true"
              print "\t["+"Installed".green+"]\n"
            else
              print "\t["+"Not Installed".red+"]\n"+"\tInstalling ...... ".yellow
              $stdout.flush
              install = `gem install #{name} -v #{ver}#{gemopts} 2>/dev/null`
              status
            end
          end
        end
      when "uninstall"
        target = File.open(options[:file])

        while gem = target.gets
          gem =~ /(.+) \((.*)\)\n/
          name = $1
          versions = $2.split(', ')

          versions.each do |ver|
            print "Checking #{name}-#{ver} ".ljust(50)
            gem_installed  = `gem list #{name} -i -v #{ver} 2>/dev/null`

            if gem_installed.chomp == "false"
              print "\t["+"Not Installed".green+"]\n"
            else
              print "\t["+"Installed".red+"]\n"+"\tUninstalling ...... ".yellow
              $stdout.flush
              uninstall = `gem uninstall -a -I -x #{name} -v #{ver} 2>/dev/null`
              status
            end
          end
        end
      when "clean"
        print "Building target list \t "
        target = File.open(options[:file])
        target_list = []

        while gem = target.gets
          gem =~ /(.+) \((.*)\)\n/
          name = $1
          versions = $2.split(', ')

          versions.each do |ver|
            target_list << "#{name} -v #{ver}"
          end
        end

        print "[DONE]\n".green
        print "Getting gem list \t "
        $stdout.flush

        source = `gem list 2>/dev/null`
        source_list = []
        status

        source.each do |gem|
          gem =~ /(.+) \((.*)\)\n/
          name = $1
          versions = $2.split(', ')

          versions.each do |ver|
            source_list << "#{name} -v #{ver}"
          end
        end

        to_install = target_list - source_list
        puts "Installing required gems" unless to_install.empty?

        to_install.each do |gem|
          print "\tInstalling #{gem.split(' -v ')[0]}-#{gem.split(' -v ')[1]} ...".ljust(50).yellow
          $stdout.flush
          install = `gem install #{gem}#{gemopts} 2>/dev/null`
          status
        end

        to_uninstall = source_list - target_list
        puts "Uninstalling unrequired gems" unless to_uninstall.empty?

        to_uninstall.each do |gem|
          print "\tUninstalling #{gem.split(' -v ')[0]}-#{gem.split(' -v ')[1]} ...".ljust(50).yellow
          $stdout.flush
          uninstall = `gem uninstall -a -I -x #{gem} 2>/dev/null`
          status
        end

        if to_install.empty? && to_uninstall.empty?
          puts "\nNo changes to be made"
        end
      when "update"
        print "Getting outdated gem list \t "
        $stdout.flush
        target = `gem outdated 2>/dev/null`
        status

        target.each do |gem|
          gem =~ /(.+) \((.*)\)/
          name = $1
          versions = $2.split(' < ')

          print "\tUpdating #{name} from #{versions[0]} to #{versions[1]}".ljust(50).yellow
          $stdout.flush
          update = `gem install #{name} -v #{versions[1]}#{gemopts} 2>/dev/null`
          status
        end
      when "prune"
        print "Getting gem list \t "
        $stdout.flush
        target = `gem list 2>/dev/null`
        status

        target.each do |gem|
          gem =~ /(.+) \((.*)\)\n/
          name = $1
          versions = $2.split(', ')

          print "Checking #{name} ...".ljust(50)
          if versions.count==1
            print "\t["+"No old versions".green+"]\n"
          else
            print "\t["+"#{versions.count-1} old versions".rjust(15).red+"]\n"
            versions.slice(1..-1).each do |ver|
              print "\tPruning #{ver} ...... ".yellow
              $stdout.flush
              prune = `gem uninstall -a -I -x #{name} -v #{ver} 2>/dev/null`
              status
            end
          end
        end
    end
  end
end