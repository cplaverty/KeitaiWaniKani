platform :ios, '8.0'
use_frameworks!
#inhibit_all_warnings!

xcodeproj 'KeitaiWaniKani'

link_with 'OperationKit', 'WaniKaniKit', 'WaniKaniKitTests', 'WaniKaniStudyQueueWidget'

#pod 'FMDB', '~> 2.5'
pod 'FMDB', :git => 'https://github.com/ccgus/fmdb.git', :branch => 'swiftFramework'
pod 'SwiftyJSON', '~> 2.3'
#pod 'CocoaLumberjack', '~> 2.0.1'
pod 'CocoaLumberjack', :git => 'https://github.com/CocoaLumberjack/CocoaLumberjack.git', :branch => 'swift_2.0'
#pod 'CocoaLumberjack/Swift', '~> 2.0.1'
pod 'CocoaLumberjack/Swift', :git => 'https://github.com/CocoaLumberjack/CocoaLumberjack.git', :branch => 'swift_2.0'

target :KeitaiWaniKani do
    pod '1PasswordExtension', '~> 1.6'
end

post_install do |installer|
    require 'fileutils'
    FileUtils.cp_r('Pods/Target Support Files/Pods-KeitaiWaniKani/Pods-KeitaiWaniKani-acknowledgements.plist', 'KeitaiWaniKani/Settings.bundle/Acknowledgements.plist', :remove_destination => true)
end
