Pod::Spec.new do |s|
  s.name          = 'ShareKit'
  s.version       = '5.0.0'
  s.platform      = :ios, '7.0'
  s.summary       = 'Drop in sharing features for all iPhone and iPad apps.'
  s.homepage      = 'http://getsharekit.com/'
  s.author        = 'ShareKit Community'
  s.source        = { :git  => 'https://github.com/ShareKit/ShareKit.git', :tag => s.version.to_s }
  s.requires_arc = true
  s.license       = { :type => 'MIT',
                      :text => %Q|Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:\n| +
                               %Q|The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.\n| +
                               %Q|THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE| }
  
  s.subspec 'Core' do |core|
    core.resource_bundle = {'ShareKit' => ['Classes/ShareKit/Core/SHKSharers.plist', 'Classes/ShareKit/Localization/*.lproj', 'Classes/ShareKit/*.png']}
    core.source_files  = 'Classes/ShareKit/{Configuration,Core,UI}/**/*.{h,m,c}', 'Classes/ShareKit/Sharers/Actions/**/*.{h,m,c}', 'Classes/ShareKit/Core NoARC/**/*.{h,m,c}'
    core.requires_arc = 'Classes/ShareKit/{Configuration,Core,UI}/**/*.{h,m,c}', 'Classes/ShareKit/Sharers/Actions/**/*.{h,m,c}'
    core.frameworks    = 'SystemConfiguration', 'Security', 'MessageUI', 'AVFoundation', 'MobileCoreServices', 'CoreMedia', 'Social'
    core.weak_frameworks = 'SafariServices' #for Add to Safari reading list
    core.dependency 'SSKeychain', '~> 1.2.2'
    core.dependency 'SAMTextView', '~> 0.2.1'
    core.dependency 'ShareKit/Reachability'
    core.dependency 'SDWebImage', '~> 3.7'
    core.dependency 'PKMultipartInputStream'
    core.dependency 'UIActivityIndicator-for-SDWebImage', '~> 1.2'
  end

  s.subspec 'Reachability' do |reachability|
    reachability.source_files = 'Classes/ShareKit/Reachability/**/*.{h,m}'
    reachability.requires_arc = false
  end

s.subspec 'Evernote' do |evernote|
    evernote.source_files = 'Classes/ShareKit/Sharers/Services/Evernote/**/*.{h,m}'
    evernote.dependency 'Evernote-SDK-iOS', '~> 1.3.1'
    evernote.dependency 'ShareKit/Core'
    evernote.libraries = 'xml2'
evernote.xcconfig = { 'HEADER_SEARCH_PATHS' => '$(SDKROOT)/usr/include/libxml2' }
  end

  s.subspec 'Facebook' do |facebook|
    facebook.source_files   = 'Classes/ShareKit/Sharers/Services/Facebook/**/*.{h,m}'
    facebook.dependency 'Facebook-iOS-SDK', '~> 3.0'
    facebook.dependency 'ShareKit/Core'
  end

  s.subspec 'Flickr' do |flickr|
    flickr.source_files = 'Classes/ShareKit/Sharers/Services/Flickr/SHK*.{h,m}'
    flickr.framework = 'SystemConfiguration', 'CFNetwork'
    flickr.dependency 'ShareKit/Core'
  end

  s.subspec 'Foursquare' do |foursquare|
    foursquare.source_files = 'Classes/ShareKit/Sharers/Services/FoursquareV2/**/*.{h,m}'
    foursquare.framework = 'CoreLocation'
    foursquare.dependency 'ShareKit/Core'
  end

  s.subspec 'Delicious' do |delicious|
    delicious.source_files = 'Classes/ShareKit/Sharers/Services/Delicious/**/*.{h,m}'
    delicious.dependency 'ShareKit/Core'
  end

  s.subspec 'Hatena' do |hatena|
    hatena.source_files = 'Classes/ShareKit/Sharers/Services/Hatena/**/*.{h,m}'
    hatena.dependency 'ShareKit/Core'
  end

  s.subspec 'Kippt' do |kippt|
    kippt.source_files = 'Classes/ShareKit/Sharers/Services/Kippt/**/*.{h,m}'
    kippt.dependency 'ShareKit/Core'
  end

   s.subspec 'Plurk' do |plurk|
    plurk.source_files = 'Classes/ShareKit/Sharers/Services/Plurk/**/*.{h,m}'
    plurk.dependency 'ShareKit/Core'
  end

   s.subspec 'Pocket' do |pocket|
    pocket.source_files = 'Classes/ShareKit/Sharers/Services/Pocket/**/*.{h,m}'
    pocket.dependency 'ShareKit/Core'
    pocket.dependency 'PocketAPI', '~> 1.0.2'
  end

  s.subspec 'Diigo' do |diigo|
    diigo.source_files = 'Classes/ShareKit/Sharers/Services/Diigo/**/*.{h,m}'
    diigo.dependency 'ShareKit/Core'
  end
  
  s.subspec 'Dropbox' do |dropbox|
    dropbox.source_files = 'Classes/ShareKit/Sharers/Services/Dropbox/**/*.{h,m}'
    dropbox.dependency 'ShareKit/Core'
    dropbox.dependency 'Dropbox-iOS-SDK', '~> 1.3.13'
  end

  s.subspec 'Instapaper' do |instapaper|
    instapaper.source_files = 'Classes/ShareKit/Sharers/Services/Instapaper/**/*.{h,m}'
    instapaper.dependency 'ShareKit/Core'
  end

  s.subspec 'LinkedIn' do |linkedin|
    linkedin.source_files = 'Classes/ShareKit/Sharers/Services/LinkedIn/**/*.{h,m}'
    linkedin.dependency 'ShareKit/Core'
  end

  s.subspec 'Pinboard' do |pinboard|
    pinboard.source_files = 'Classes/ShareKit/Sharers/Services/Pinboard/**/*.{h,m}'
    pinboard.dependency 'ShareKit/Core'
  end

  s.subspec 'Readability' do |readability|
    readability.source_files = 'Classes/ShareKit/Sharers/Services/Readability/**/*.{h,m}'
    readability.dependency 'ShareKit/Core'
  end

  s.subspec 'Tumblr' do |tumblr|
    tumblr.source_files = 'Classes/ShareKit/Sharers/Services/Tumblr/**/*.{h,m}'
    tumblr.dependency 'ShareKit/Core'
  end

  s.subspec 'Twitter' do |twitter|
    twitter.source_files = 'Classes/ShareKit/Sharers/Services/Twitter/**/*.{h,m}'
    twitter.framework = 'Twitter','Social'
    twitter.dependency 'ShareKit/Core'
  end

 s.subspec 'SinaWeibo' do |sinaweibo|
    sinaweibo.source_files = 'Classes/ShareKit/Sharers/Services/Sina Weibo/**/*.{h,m}'
    sinaweibo.dependency 'ShareKit/Core'
    sinaweibo.framework = 'Social'
  end

  s.subspec 'Vkontakte' do |vkontakte|
    vkontakte.source_files = 'Classes/ShareKit/Sharers/Services/Vkontakte/**/*.{h,m}'
    vkontakte.dependency 'ShareKit/Core'
  end

  s.subspec 'Instagram' do |instagram|
    instagram.source_files = 'Classes/ShareKit/Sharers/Services/Instagram/**/*.{h,m}'
    instagram.dependency 'ShareKit/Core'
  end
  
  s.subspec 'Imgur' do |imgur|
    imgur.source_files = 'Classes/ShareKit/Sharers/Services/Imgur/**/*.{h,m}'
    imgur.dependency 'ShareKit/Core'
  end
  
  #s.subspec 'Pinterest' do |pinterest|
  #  pinterest.source_files = 'Classes/ShareKit/Sharers/Services/Pinterest/**/*.{h,m}'
  #  pinterest.dependency 'PinterestSDK'
  #  pinterest.dependency 'ShareKit/Core'
  #end
  
  s.subspec 'WhatsApp' do |whatsapp|
      whatsapp.source_files = 'Classes/ShareKit/Sharers/Services/WhatsApp/**/*.{h,m}'
      whatsapp.dependency 'ShareKit/Core'
  end

  s.subspec 'OneNote' do |onenote|
   onenote.source_files = 'Classes/ShareKit/Sharers/Services/OneNote/**/*.{h,m}'
   onenote.dependency 'ShareKit/Core'
   onenote.dependency 'ISO8601DateFormatter'
   onenote.dependency 'LiveSDK'
  end

  s.subspec 'YouTube' do |youtube|
    youtube.source_files = 'Classes/ShareKit/Sharers/Services/YouTube/**/*.{h,m}'
    youtube.dependency 'ShareKit/Core'
    youtube.dependency 'GoogleAPIClient/YouTube'
  end

  s.subspec 'GooglePlus' do |googleplus|
    googleplus.source_files = 'Classes/ShareKit/Sharers/Services/Google Plus/**/*.{h,m}'
    googleplus.vendored_frameworks = 'Frameworks/GooglePlus.framework'
    googleplus.resource = "Frameworks/GooglePlus.bundle"
    googleplus.framework = 'AssetsLibrary', 'CoreLocation', 'CoreMotion', 'CoreGraphics', 'CoreText', 'MediaPlayer', 'Security', 'SystemConfiguration', 'AddressBook'
    googleplus.dependency 'ShareKit/Core'
    googleplus.dependency 'GoogleAPIClient/Plus'
    googleplus.dependency 'OpenInChrome'
    googleplus.dependency 'gtm-logger'
    end

end
