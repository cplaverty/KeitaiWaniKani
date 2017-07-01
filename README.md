# Mobile AlliCrab

This unofficial app for [WaniKani](https://www.wanikani.com) improves the experience of doing WaniKani lessons and reviews while on iOS devices.  Please note that a WaniKani account is required to use this app.

[Forum page](https://community.wanikani.com/t/iOS-Mobile-AlliCrab-for-WaniKani/10065)

[Download from App Store](https://itunes.apple.com/us/app/keitaiwanikani/id1031055291?ls=1&mt=8)

Features:
* Do reviews and lessons with an in-app web browser, with support for community-produced user scripts.  (All user scripts are disabled by default and must be enabled in the app settings.)
    * Jitai: https://community.wanikani.com/t/Jitai-字体-The-font-randomizer-that-fits/12617
    * WaniKani Override (also known as the "ignore answer" script): https://community.wanikani.com/t/Userscript-Wanikani-Override-ignore-answer-button-active-support/17999
    * WaniKani Improve: https://community.wanikani.com/t/WaniKani-Improve-222-—-faster-and-smarter-reviews/2858
    * Markdown Notes: https://community.wanikani.com/t/Userscript-Markdown-Notes-updated/11462
    * WaniKani Hide Mnemonics: https://community.wanikani.com/t/Userscript-WaniKani-hide-mnemonics/3923
* 1Password support for auto-filling your WaniKani login details
* Receive notifications when reviews are due
* Lists upcoming reviews in the review timeline
* Progress for current-level radicals and kanji, including time until next review and quickest time to Guru
* Notification Centre widget

## How to get started
Since the project uses an app extension with a shared App Group, you'll have to create a new App Group and App ID using the Apple Developer Portal, then change the app bundle identifiers in the main target and app extension to match. A [fastlane](https://github.com/fastlane/fastlane) lane has been be prepared to take care of all that for you. Here's what you need to do:
- Have a registered Apple Developer Account.
- Install [fastlane](https://github.com/fastlane/fastlane)
- Clone / download the project
- Edit "fastlane/Appfile" and set your own bundle identifier, plus set your Apple ID and Team ID
- Run `fastlane setupID` using the command line
- Select your signing identity for the `AlliCrab` and `WaniKaniStudyQueueWidget` targets.
- You should now be able to run the project on your device!

You can use `fastlane resetID` to reset the bundle identifiers to the default values again, which may be useful if you want to submit pull requests without your custom bundle identifiers.

You can run `git update-index --assume-unchanged fastlane/Appfile` if you want to keep changes of Appfile locally without having to push them. (`Use git update-index --no-assume-unchanged fastlane/Appfile` to undo this.)
