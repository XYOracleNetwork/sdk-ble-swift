xcodebuild clean -workspace XyBleSdk.xcworkspace -scheme "Pods-XyBleSdk iOS" &&
xcodebuild clean -workspace XyBleSdk.xcworkspace -scheme "XyBleSdk iOS"

xcodebuild build -workspace XyBleSdk.xcworkspace -scheme "Pods-XyBleSdk iOS" &&
xcodebuild build -workspace XyBleSdk.xcworkspace -scheme "XyBleSdk iOS" &&
pod lib lint

