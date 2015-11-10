platform :ios, '8.0'
use_frameworks!
#inhibit_all_warnings!

xcodeproj 'KeitaiWaniKani'

link_with 'OperationKit', 'WaniKaniKit'

pod 'Alamofire'
#pod 'FMDB', '~> 2.5'
pod 'FMDB', :git => 'https://github.com/ccgus/fmdb.git', :branch => 'swiftFramework'
pod 'SwiftyJSON'
pod 'CocoaLumberjack/Swift'

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
    
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            if config.name == 'Release'
                config.build_settings['SWIFT_OPTIMIZATION_LEVEL'] = '-Owholemodule'
                else
                config.build_settings['SWIFT_OPTIMIZATION_LEVEL'] = '-Onone'
            end
        end
    end
    
end
