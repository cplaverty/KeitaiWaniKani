platform :ios, '9.0'
use_frameworks!

pod 'FMDB', '~> 2.7'

target 'WaniKaniKit'
target 'WaniKaniStudyQueueWidget'

target 'WaniKaniKitTests'

target 'AlliCrab' do
    pod '1PasswordExtension', '~> 1.8'
end

post_install do |installer|
    require 'fileutils'
    FileUtils.cp_r('Pods/Target Support Files/Pods-AlliCrab/Pods-AlliCrab-acknowledgements.plist', 'AlliCrab/Settings.bundle/Acknowledgements.plist', :remove_destination => true)
end
