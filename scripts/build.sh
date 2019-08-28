pod install
pod update

xcodebuild clean -workspace XyBleSdk.xcworkspace -scheme "XyBleSdk iOS"

xcodebuild build -workspace XyBleSdk.xcworkspace -scheme "XyBleSdk iOS"

