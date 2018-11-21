[logo]: https://www.xy.company/img/home/logo_xy.png

![logo]

# sdk-ble-ios
A Bluetooth library, primarily for use with XY Finder devices but can be implemented to communicate with any Bluetooth device, with monitoring capability if the device emits an iBeacon signal. The library is designed to aleviate the delegate-based interaction with Core Bluetooth classes and presents a straightforward API that allows the developer to write asyncronous code in a syncronous manner. The libray utlizes the [Google Promises](https://github.com/google/promises) library as a dependency.

## Requirements

- iOS 11.0+
- Xcode 9.3+
- Swift 3.1+

## Installation

### CocoaPods

[CocoaPods](https://cocoapods.org) is a dependency manager for Cocoa projects. You can install it with the following command:

```bash
$ gem install cocoapods
```

> CocoaPods 1.1+ is required.

To integrate into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '11.0'
use_frameworks!

target '<Your Target Name>' do
    pod 'XYSdkBle', '~> 0.1.0'
end
```

Then, run the following command:

```bash
$ pod install
```

## Code Example
Talking to a Bluetooth device using Core Bluetooth is a drag. The developer needs to monitor delegate methods from `CBCentral` and `CBPeripheral` with no clear path to handling multiple connections. Often tutorial code for Core Bluetooth is a chain of use-case specific method calls from within these delegates.

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Author

Darren Sutherland, darren@xyo.network

## License

XyBleSdk is available under the MIT license. See the LICENSE file for more info.
