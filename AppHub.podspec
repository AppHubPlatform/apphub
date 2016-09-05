#
# Be sure to run `pod lib lint AppHub.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "AppHub"
  s.version          = "0.5.1"
  s.summary          = "This is the iOS client for AppHub: https://apphub.io"

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!
  s.description      = <<-DESC
  AppHub lets you instantly update React Native apps without resubmitting to the App Store.
                       DESC

  s.homepage         = "https://github.com/AppHubPlatform/apphub-ios"
  s.license          = 'MIT'
  s.author           = { "Matthew Arbesfeld" => "support@apphub.com" }
  s.source           = { :git => "https://github.com/AppHubPlatform/apphub-ios.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/AppHubPlatform'

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.exclude_files = 'AppHub/AppHub/React/**/*'
  s.source_files = [
    'AppHub/AppHub/**/*.{h,m,c}'
  ]
  s.public_header_files = [
    'AppHub/AppHub/AHBuildManager.h',
    'AppHub/AppHub/AppHub.h',
    'AppHub/AppHub/AHBuild.h',
    'AppHub/AppHub/AHDefines.h',
  ]
  s.libraries = 'z'
  s.frameworks = 'SystemConfiguration'
  s.dependency 'React/Core'
end
