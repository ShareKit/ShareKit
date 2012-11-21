# Copyright (c) 2011 Kim Hunter.
# All rights reserved.
# 
# Redistribution and use in source and binary forms are permitted provided
# that the above copyright notice and this paragraph are duplicated in all
# such forms and that any documentation, advertising materials, and other
# materials related to such distribution and use acknowledge that the
# software was developed by the Kim Hunter. The name of the copyright holder
# may not be used to endorse or promote products derived from this software
# without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
# WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

require 'rubygems'
require 'rake/clean'
require 'fileutils'
require 'yaml'
require 'digest/md5'
require "open-uri"

SRC_FOLDER = "src"
RES_FOLDER =  "#{SRC_FOLDER}/resources"

# Exclude any paths that we don't need
# EXCLUDE_PATTERNS = /(Reachability\.[hm]|Evernote|Pinboard|Tumblr|Instapaper|Delicious|Google Reader|SBJSON|Vkontakte|LinkedIn|FoursquareV2|Flickr|Read It Later|SHKMail|SHKCopy|SHKPrint|SHKTextMessage|SHKPhotoAlbum|SHKSafari)/i
EXCLUDE_PATTERNS = /([^B]SBJSON)/i

ALL_PATTERN = '**/*.[hmc]'
# Get list of all source files we need 
base_source_dirs = [  "Classes/ShareKit/UI/"                + ALL_PATTERN,
                      "Classes/ShareKit/Configuration/"     + ALL_PATTERN,
                      "Classes/ShareKit/Customize UI/"      + ALL_PATTERN,
                      "Classes/ShareKit/Core/"              + ALL_PATTERN,
                      "Classes/ShareKit/Sharers/Actions/"   + ALL_PATTERN,
                      "Classes/ShareKit/Sharers/Services/Twitter/"   + ALL_PATTERN,
                      "Classes/ShareKit/Sharers/Services/Facebook/"  + ALL_PATTERN,
                      "Classes/ShareKit/Sharers/Services/Weibo/"  + ALL_PATTERN,
                      "Classes/ShareKit/Sharers/Services/Sina Weibo/"  + ALL_PATTERN,
                      "Submodules/facebook-ios-sdk/src/*.[hmc]",
                      "Submodules/facebook-ios-sdk/src/JSON/*.[hmc]",
                      "Submodules/JSONKit/"                 + ALL_PATTERN,
                      "Submodules/sskeychain/"              + 'SSKeychain.[hm]']

combined_sources = base_source_dirs.map {|d| FileList[d] }.flatten
SOURCE_FILES = combined_sources.select do |f| 
  puts " EXCLUDING #{f}" if f =~ EXCLUDE_PATTERNS
  !(f =~ EXCLUDE_PATTERNS) 
end

puts SOURCE_FILES

CLEAN.include([SRC_FOLDER, RES_FOLDER])

task :default do
  system "rake -T"
end

def inc_revision version
  v = version.to_s.split('.')
  if v.size > 1
    last = v.size - 1 
    if v.last =~ /^[0-9]+(.*)?$/
      v[last] = (v.last.to_i + 1).to_s
      v[last] += $1.to_s unless $1.nil?
    end
  end
  v.join '.'
end

desc "Create KitSpec"
task :kitspec do
  unless File.exists? 'KitSpec'
    kspec = {} 
    kspec['name'] = File.basename Dir.pwd.downcase
    kspec['version'] = 0.1
    f = File.open('KitSpec', 'w')
    f.write kspec.to_yaml
    f.close    
  end
end

desc "Publish"
task :publish => [:kitspec, :kit] do
  puts `kit publish-local`
end

desc "Bump Version"
task :bump  do
  kitspec = YAML::load_file 'KitSpec'
  old = kitspec['version']
  kitspec['version'] = inc_revision(old)
  File.open('KitSpec', 'w') {|f| f.write kitspec.to_yaml }
  kitspec = YAML::load_file 'KitSpec'
  File.open('KitSpec', 'w') {|f| f.write kitspec.to_yaml }
  puts "Updated from #{old} -> #{kitspec['version']}"
end

desc "Find Dups"
task :find_dups do
  basenames = SOURCE_FILES.map {|path| File.basename path}
  dups = basenames.select {|fname| basenames.count(fname) > 1 }
  raise "Duplicates Found CANNOT CONTINUE Dups: \n#{dups.uniq}" unless dups.size.zero?
end

desc "Create Folders"
task :create_folders => [:clean] do
  Dir.mkdir SRC_FOLDER
  Dir.mkdir RES_FOLDER
end


task :mods do
  SOURCE_FILES.each do |orig_file|
      maybe_dirty_file = "#{SRC_FOLDER}/#{File.basename(orig_file)}"
      if Digest::MD5.file(maybe_dirty_file) != Digest::MD5.file(orig_file)
        if orig_file =~ /Submodules/
          puts "changed, but not copying changes into submodule for #{maybe_dirty_file}"
        else
          FileUtils.cp maybe_dirty_file, orig_file
          puts "found changes in #{maybe_dirty_file}"
        end
      end
  end
end

desc "Transform project into Kit Package"
task :kit => [:create_folders, :find_dups] do
  
  SOURCE_FILES.each do |orig_file| 
    FileUtils.cp orig_file, "#{SRC_FOLDER}/#{File.basename(orig_file)}"
  end
  
  bundles = FileList["Classes/ShareKit/**/*.bundle"] + FileList["Submodules/**/*.bundle"]
  
  bundles.each do |resource|
    puts "Copying Resource " + resource
    FileUtils.cp_r resource, RES_FOLDER + "/"
  end
  puts "Copied #{SOURCE_FILES.size} files"
  
  files_to_overwrite = FileList["overwrite/*"];
  files_to_overwrite.each do |file|
    FileUtils.cp file, "#{SRC_FOLDER}/#{File.basename(file)}"
    puts "Overwriting #{File.basename(file)} in src/"
  end
  
end
