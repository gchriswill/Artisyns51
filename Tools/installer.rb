#!/usr/bin/env ruby -wU

# Code Implementations/Modifications by Christopher Gonzalez D.K.A "gchriswill" at Parthenon Studio
# email: gchriswill -at- me -dot- com
# website: N/A
#
# Project Management by Elianna Bentz "Eli" at Parthenon Studio
# email: eliannabent -at- gmail -dot- com
# website: N/A

####################################################################################
# Requirment: Must have already performed a Deployment build in order to be executed
# inside of the root directory of the project repository.
# Terminal Command Example: ./build.rb -dep
####################################################################################

require 'open3'
require 'fileutils'
require 'pathname'
require 'rexml/document'
include REXML

libdir = "."
Dir.chdir libdir

@svn_root = ".."
Dir.chdir @svn_root
@svn_root = Dir.pwd

###################################################################
# sub routines
###################################################################

def create_logs
  @build_log = File.new("#{@svn_root}/Installer/_installer.log", "w")
  @build_log.write("Artisyns51 INSTALLER LOG: #{`date`}\n\n")
  @build_log.flush
  @error_log = File.new("#{@svn_root}/Installer/_error.log", "w")
  @error_log.write("Artisyns51 INSTALLER ERROR LOG: #{`date`}\n\n")
  @error_log.flush
  trap("SIGINT") { die }
end

def die
  close_logs
  exit 0
end

def close_logs
  @build_log.close
  @error_log.close
end

def log_build(str)
  @build_log.write(str)
  @build_log.write("\n\n")
  @build_log.flush
end

def log_error(str)
  @error_log.write(str)
  @error_log.write("\n\n")
  @error_log.flush
end

def cmd(commandString)
  out = ""
  err = ""

  Open3.popen3(commandString) do |stdin, stdout, stderr|
    out = stdout.read
    err = stderr.read
  end
  log_error(out)
  log_error(err)
end


def getversion()
  theVersion = "0.0.0"

  f = File.open("#{@installer_root}/System/Library/Extensions/Artisyns51.kext/Contents/Info.plist", "r")
  str = f.read
  theVersion = str.match(/<key>CFBundleShortVersionString<\/key>\n.*<string>(.*)<\/string>/).captures[0]
  f.close

  puts"  version: #{theVersion}"
  return theVersion;
end

###################################################################
# Installer Builder Snippets
###################################################################

create_logs()

@installer_root = "#{@svn_root}/Build/InstallerRoot"
@version = getversion()
@build_folder = "#{@svn_root}/Build/Artisyns51-#{@version}"

puts "  Creating installer directory structure..."
cmd("rm -rfv \"#{@build_folder}\"")
cmd("mkdir -pv \"#{@build_folder}\"")

cmd("cp \"#{@svn_root}/Tools/Uninstall Artisyns51.scpt\"           \"#{@installer_root}\"/Applications/Artisyns51")
cmd("cp \"#{@svn_root}/License.txt\"                                \"#{@installer_root}\"/Applications/Artisyns51")
cmd("cp \"#{@svn_root}/Installer/ReadMe.rtf\"                       \"#{@installer_root}\"/Applications/Artisyns51")

puts "  Building Package -- this could take a while..."
puts `pkgbuild --root \"#{@installer_root}\" --identifier me.gchriswill.artisyns51 --version #{@version} --install-location "/" \"#{@build_folder}/Artisyns51.pkg\" --ownership preserve  --scripts \"#{@svn_root}/Installer/scripts\" --sign \"Developer ID Installer: me.gchriswill.artisyns51\"`

puts "  Copying readme, license, etc...."
cmd("cp \"#{@svn_root}/License.txt\" \"#{@build_folder}\"")
cmd("cp \"#{@svn_root}/Installer/ReadMe.rtf\" \"#{@build_folder}\"")
cmd("cp \"#{@svn_root}/Tools/Uninstall Artisyns51.scpt\" \"#{@build_folder}\"")

puts "  Creating Disk Image..."
cmd("rm -rfv \"#{@svn_root}/Installer/Artisyns51-#{@version}.dmg\"")
cmd("hdiutil create -srcfolder \"#{@build_folder}\" \"#{@svn_root}/Build/Artisyns51-#{@version}.dmg\"")

puts "  All done!"

close_logs
puts ""
exit 0
