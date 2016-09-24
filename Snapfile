# A list of devices you want to take the screenshots from
devices([
    "iPhone 4s",
    "iPhone 5s",
    "iPhone 6",
    "iPhone 6 Plus",
    "iPad Air",
    "iPad Pro"
])

languages([
  "en-US"
])

# Arguments to pass to the app on launch. See https://github.com/fastlane/snapshot#launch_arguments
#launch_arguments(["-LOGIN_COOKIE <login cookie goes here>"])

# The name of the scheme which contains the UI Tests
scheme "AlliCrabUITests"

# Where should the resulting screenshots be stored?
output_directory "./screenshots"

clear_previous_screenshots true

app_identifier "uk.me.laverty.KeitaiWaniKani"
reinstall_app true
clear_previous_screenshots true
number_of_retries 3
skip_open_summary true
ios_version "9.3"

# Choose which project/workspace to use
# project "./Project.xcodeproj"
# workspace "./Project.xcworkspace"

# For more information about all available options run
# snapshot --help
