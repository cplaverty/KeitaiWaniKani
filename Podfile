platform :ios, '9.0'
use_frameworks!
inhibit_all_warnings!

pod 'sqlite3'
pod 'sqlite3/fts5'
pod 'FMDB/standalone'

target 'WaniKaniKit'
target 'WaniKaniStudyQueueWidget'

target 'WaniKaniKitTests'

target 'AlliCrab' do
    pod '1PasswordExtension'
end

post_install do |installer|
    require 'fileutils'
    FileUtils.cp_r('Pods/Target Support Files/Pods-AlliCrab/Pods-AlliCrab-acknowledgements.plist', 'AlliCrab/Settings.bundle/Acknowledgements.plist', :remove_destination => true)
end
