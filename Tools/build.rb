#!/usr/bin/env ruby -wU

require 'open3'
require 'fileutils'
require 'pathname'
require 'rexml/document'
include REXML

libdir = "."
Dir.chdir libdir

if(ARGV.length != 1)
  puts "usage: "
  puts "build.rb <required:configuration (Development|Deployment)>"
  exit 0;
end

configuration = ARGV[0]
out = nil
err = nil

@svn_root = ".."
@source = "#{@svn_root}/Source"
@source_sfb = "#{@svn_root}/SoundflowerBed"

configuration = "Development" if configuration == "dev"
configuration = "Deployment" if configuration == "dep"

`sudo rm -rf #{@svn_root}/Build/InstallerRoot`

puts "  Building the new Soundflower.kext with Xcode"

Dir.chdir("#{@source}")
Open3.popen3("xcodebuild -project Soundflower.xcodeproj -target Soundflower -configuration #{configuration} clean build") do |stdin, stdout, stderr|
  out = stdout.read
  err = stderr.read
end

`sudo chown -R root #{@svn_root}/Build/InstallerRoot/System/Library/Extensions/Soundflower.kext`
`sudo chgrp -R wheel #{@svn_root}/Build/InstallerRoot/System/Library/Extensions/Soundflower.kext`

if /BUILD SUCCEEDED/.match(out)
  puts "    BUILD SUCCEEDED"
else
  puts "    BUILD FAILED"
end

puts "  Done."
puts ""
exit 0
