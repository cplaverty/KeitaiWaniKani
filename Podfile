platform :ios, '8.0'
use_frameworks!
#inhibit_all_warnings!

xcodeproj 'KeitaiWaniKani'

link_with 'OperationKit', 'WaniKaniKit', 'WaniKaniStudyQueueWidget'

pod 'Alamofire', '~> 3.0'
#pod 'FMDB', '~> 2.5'
pod 'FMDB', :git => 'https://github.com/ccgus/fmdb.git', :branch => 'swiftFramework'
pod 'SwiftyJSON', '~> 2.3'
pod 'CocoaLumberjack', '~> 2.1.0-rc'
pod 'CocoaLumberjack/Swift', '~> 2.1.0-rc'

target :KeitaiWaniKani do
    pod '1PasswordExtension'
end

target :WaniKaniKitTests do
    pod 'OHHTTPStubs'
    pod 'OHHTTPStubs/Swift'
end

post_install do |installer|
    require 'fileutils'
    FileUtils.cp_r('Pods/Target Support Files/Pods-KeitaiWaniKani/Pods-KeitaiWaniKani-acknowledgements.plist', 'KeitaiWaniKani/Settings.bundle/Acknowledgements.plist', :remove_destination => true)
end
