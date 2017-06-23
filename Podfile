platform :ios, '8.0'
use_frameworks!

pod 'FMDB', '~> 2.7'
pod 'SwiftyJSON', '~> 3.1'
pod 'CocoaLumberjack/Swift', '~> 3.2'

target 'OperationKit'
target 'WaniKaniKit'

target 'AlliCrab' do
    pod '1PasswordExtension', '~> 1.8'
end

target 'WaniKaniStudyQueueWidget'

target 'OperationKitTests'
target 'WaniKaniKitTests' do
    pod 'OHHTTPStubs', '~> 6.0'
    pod 'OHHTTPStubs/Swift', '~> 6.0'
end

post_install do |installer|
    require 'fileutils'
    FileUtils.cp_r('Pods/Target Support Files/Pods-AlliCrab/Pods-AlliCrab-acknowledgements.plist', 'AlliCrab/Settings.bundle/Acknowledgements.plist', :remove_destination => true)
    
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
