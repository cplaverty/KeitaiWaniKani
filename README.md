# Mobile AlliCrab
### Formerly known as KeitaiWaniKani

This unofficial app for [WaniKani](https://www.wanikani.com) improves the experience of doing WaniKani lessons and reviews while on iOS devices.  Please note that a WaniKani account is required to use this app.

[Forum page](https://community.wanikani.com/t/iOS-Mobile-AlliCrab-for-WaniKani/10065)

[Download from App Store](https://itunes.apple.com/us/app/keitaiwanikani/id1031055291?ls=1&mt=8)

Features:
* Do reviews and lessons with an in-app web browser, with support for community-produced user scripts.  (All user scripts are disabled by default and must be enabled in the app settings.)
    * Jitai: https://community.wanikani.com/t/Jitai-字体-The-font-randomizer-that-fits/12617
    * WaniKani Override (also known as the "ignore answer" script): https://community.wanikani.com/t/Userscript-Wanikani-Override-ignore-answer-button-active-support/17999
    * WaniKani Double Check: https://community.wanikani.com/t/UserScript-WaniKani-Double-Check/8396
    * WaniKani Improve: https://community.wanikani.com/t/WaniKani-Improve-222-—-faster-and-smarter-reviews/2858
    * Markdown Notes: https://community.wanikani.com/t/Userscript-Markdown-Notes-updated/11462
    * WaniKani Hide Mnemonics: https://community.wanikani.com/t/Userscript-WaniKani-hide-mnemonics/3923
    * WaniKani Reorder Ultimate: https://community.wanikani.com/t/Wanikani-Reorder-Ultimate/8269
* 1Password support for auto-filling your WaniKani login details
* Receive notifications when reviews are due
* Lists upcoming reviews in the review timeline
* Progress for current-level radicals and kanji, including time until next review and quickest time to Guru
* Notification Centre widget

## How to get started
Since the project uses an app extension / widget, you'd have to create a new App Group, AppID on the Apple developer portal, and change the app bundle identifiers in the main target and app extension. However, a [fastlane](https://github.com/fastlane/fastlane) lane has been be prepared to take care of all that for you. Here's what you need to do:
- Have a registered Apple Developer Account.
- Install [fastlane](https://github.com/fastlane/fastlane)
- Clone / download the project
- Open the file in "fastlane/Fastfile"
- In the Fastfile, set your own bundle identifier and Apple ID at the very top of the document
- Run `fastlane setupID` using the command line
- Select your signing identity for the `AlliCrab` and `WaniKaniStudyQueueWidget` targets.
- You should now be able to run the project on your device!

You can use `fastlane resetID` to reset the bundle identifiers to the default values again, which may be useful if you want to submit pull requests without your custom bundle identifiers.

You can run `git update-index --assume-unchanged fastlane/Fastfile` if you want to keep changes of Fastfile locally without having to push them. (`Use git update-index --no-assume-unchanged fastlane/Fastfile` to undo this.)
