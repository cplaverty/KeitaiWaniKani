platform :ios, '8.0'
use_frameworks!

pod 'FMDB'
pod 'SwiftyJSON'
pod 'CocoaLumberjack/Swift'

target 'OperationKit'
target 'WaniKaniKit'

target 'AlliCrab' do
    pod '1PasswordExtension'
end

target 'WaniKaniStudyQueueWidget'

target 'OperationKitTests'
target 'WaniKaniKitTests' do
    pod 'OHHTTPStubs'
    pod 'OHHTTPStubs/Swift'
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
