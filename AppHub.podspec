#
#  Be sure to run `pod spec lint AppHub.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|

  s.name         = "AppHub"
  s.version      = "0.1.1"
  s.summary      = "AppHub lets you instantly update code and assets in a React Native app."

  s.description  = <<-DESC
                   apphub-ios is a client library for instantly updating code and assets in a React Native app.

                   Use the [AppHub Dashboard](https://dashboard.apphub.io) to upload updates and manage
                   versions of your app.

                   ## Features

                   - Instantly update app code and images without resubmitting to TestFlight or the App Store.
                   - Manage compatability between multiple native and JavaScript versions of your app.
                   - Download updates in the background, or while your app is executing.
                   - Seamlessly "hot swap" updates during app use.
                   - Require that testers and users are on the latest version of your app.

                   DESC

  s.homepage     = "https://apphub.io"
  s.documentation_url = "http://docs.apphub.io"

  s.license      = "BSD"

  s.author    = "AppHub"
  s.social_media_url   = "http://twitter.com/AppHubPlatform"

  s.platform     = :ios, "8.0"

  s.source       = { :git => "https://github.com/AppHubPlatform/apphub-ios.git", :tag => "0.1.1" }

  s.source_files  =  "react-native/0.12.0/React/**/*.{h}", "AppHub/AppHub/**/*.{h,m,c}", "AppHub/AppHubTests/Shims.m"
  s.private_header_files = "react-native/0.12.0/React/**/*.{h}"

  s.frameworks = "SystemConfiguration"
  s.libraries = "z"

end
