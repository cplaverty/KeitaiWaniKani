platform :ios, '8.0'
use_frameworks!

target 'AlliCrab' do
    pod 'FMDB'
    pod 'SwiftyJSON', :git => 'https://github.com/cplaverty/SwiftyJSON.git', :branch => 'swift3'
    pod 'CocoaLumberjack/Swift', :git => 'https://github.com/cplaverty/CocoaLumberjack.git'
    pod '1PasswordExtension'
    #pod 'Charts', :git => 'https://github.com/danielgindi/Charts.git', :branch => 'Swift-3.0'
    
    target 'OperationKit'
    target 'WaniKaniKit'
    
    target 'WaniKaniStudyQueueWidget' do
        inherit! :search_paths
    end
    
    target 'OperationKitTests' do
        inherit! :search_paths
    end
    
    target 'WaniKaniKitTests' do
        inherit! :search_paths
        pod 'OHHTTPStubs'
        pod 'OHHTTPStubs/Swift'
    end
end

post_install do |installer|
    require 'fileutils'
    FileUtils.cp_r('Pods/Target Support Files/Pods-AlliCrab/Pods-AlliCrab-acknowledgements.plist', 'KeitaiWaniKani/Settings.bundle/Acknowledgements.plist', :remove_destination => true)
    
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
