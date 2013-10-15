Pod::Spec.new do |s|

  s.name         = "SHK-GTM"
  s.version      = "0.0.1"
  s.summary      = "google-toobox-for-mac with selected files needed for ShareKit's Google Plus sharer"
  s.homepage     = "http://code.google.com/p/google-toolbox-for-mac/"
  s.license      = { :type => 'Apache License, Version 2.0', :file => 'COPYING' }
  s.author       = "Google Inc."


  # ――― Platform Specifics ――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  If this Pod runs only on iOS or OS X, then specify the platform and
  #  the deployment target. You can optionally include the target after the platform.
  #

  # s.platform     = :ios
  # s.platform     = :ios, '5.0'

  #  When using multiple platforms
  # s.ios.deployment_target = '5.0'
  # s.osx.deployment_target = '10.7'
  s.source       = { :svn => "http://google-toolbox-for-mac.googlecode.com/svn/trunk" }
  s.source_files  = 'Foundation/GTMLogger.{h,m}', 'GTMDefines.h', 'DebugUtils/GTMMethodCheck.{h,m}', 'Foundation/GTMNSString+URLArguments.{h,m}', 'Foundation/GTMNSDictionary+URLArguments.{h,m}', 'Foundation/GTMGarbageCollection.{h,m}'

end
