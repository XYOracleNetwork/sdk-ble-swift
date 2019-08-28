[logo]: https://cdn.xy.company/img/brand/XY_Logo_GitHub.png

[![logo]](https://xy.company)

[![BCH compliance](https://bettercodehub.com/edge/badge/XYOracleNetwork/sdk-ble-swift?branch=master)](https://bettercodehub.com/)

# sdk-ble-ios

A Bluetooth library, primarily for use with XY Finder devices but can be implemented to communicate with any Bluetooth device, with monitoring capability if the device emits an iBeacon signal. The library is designed to aleviate the delegate-based interaction with Core Bluetooth classes and presents a straightforward API, allowing the developer to write asyncronous code in a syncronous manner. The libray utlizes the [Google Promises](https://github.com/google/promises) library as a dependency.

## Requirements

-   iOS 11.0+
-   MacOS 10.13+
-   Xcode 10.1+
-   Swift 4.2+

## Installation

### CocoaPods

> Note that CocoaPods support is only for iOS currently

[CocoaPods](https://cocoapods.org) is a dependency manager for Cocoa projects. You can install it with the following command:

```bash
$ gem install cocoapods
```

> CocoaPods 1.6.0.beta.2+ is required.

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

### Carthage

[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager that builds your dependencies and provides you with binary frameworks.

You can install Carthage with [Homebrew](http://brew.sh/) using the following command:

```bash
$ brew update
$ brew install carthage
```

To integrate into your Xcode project using Carthage, specify it in your `Cartfile`:

```ogdl
github "XYOracleNetwork/sdk-ble-swift" ~> 0.1.0
```

Run `carthage update --use-submodules` to build the framework and drag the built `XyBleSdk.framework`, `FBLPromises.framework` and `Promises.framework` to the _Linked Frameworks and Libraries_ of your Xcode project. Then switch to the _Build Phases_ tab and add a _New run script phase_. Expand _Run Script_ and add the following to the _Shell_ text field:

    /usr/local/bin/carthage copy-frameworks

Click the + button under _Input Files_ and add:

    $(SRCROOT)/Carthage/Build/<target platform>/Promises.framework
    $(SRCROOT)/Carthage/Build/<target platform>/FBLPromises.framework
    $(SRCROOT)/Carthage/Build/<target platform>/XyBleSdk.framework

Finally, you will need to add a _New Copy Files Phase_, selecting _Frameworks_ for the _Destination_ and adding the three frameworks, ensuring the _Code Sign On Copy_ boxes are checked.

## Overview

Talking to a Bluetooth device using Core Bluetooth is a drag. The developer needs to monitor delegate methods from `CBCentral` and `CBPeripheral`, with no clear path to handling multiple connections. Tutorial code for Core Bluetooth is often a chain of use-case specific method calls from within these delegates, which can lead to frustration when trying to apply the code in a more resusable pattern. Bluetooth devices are often not predictable in their reponse times due to firmware and environmental conditions, which can make them tricky to deal with, especially if the application requires multiple, disparate devices connected to operate properly.

## Code Example

The XyBleSdk provides a simple interface to communicating with an XY Finder or other Bluetooth device. Let's take a look at an example for an XY Finder device:

```swift
let device = XYFinderDeviceFactory.build(from: "xy:ibeacon:a44eacf4-0104-0000-0000-5f784c9977b5.20.28772")
var batteryLevel: Int?
device.connection {
    batteryLevel = device.get(BatteryService.level, timeout: .seconds(10)).asInteger
    if let level = batteryLevel, level > 15 {
        self.batteryStatus = "Battery at \(level)"
    } else {
        self.batteryStatus = "Battery level low"
    }
}
```

The `XYFinderDeviceFactory` can build a device from a string, peripheral, etc. Using `connection` manages the wrangling of the `CBCentral` and associated `CBPeripheral` delegates, ensuring you have a connection before trying any GATT operation(s) in the block.

The `get`, `set`, and `notify` methods operate on the specified device and block until the result is returned. This allows the developer to write syncronous code without waiting for a callback or delegate method to be called, or deal with the underlying promises directly. Each operation can also take a timeout if so desired; the default is 30 seconds.

Once all the operations have completed, you can use `then` if there are post actions you wish to run:

```swift
let device = XYFinderDeviceFactory.build(from: "xy:ibeacon:a44eacf4-0104-0000-0000-5f784c9977b5.20.28772")
var batteryLevel: Int = 0
device.connection {
    batteryLevel = device.get(BatteryService.level, timeout: .seconds(10)).asInteger
    if let level = batteryLevel, level > 15 {
        self.batteryStatus = "Battery at \(level)"
    } else {
        self.batteryStatus = "Battery level low"
    }
}.then {
    self.showBatteryNotification(for: batteryLevel)
}
```

You can check for an error from your operations by using `hasError` in the result. The error is of type `XYFinderBluetoothError`.

```swift
let device = XYFinderDeviceFactory.build(from: "xy:ibeacon:a44eacf4-0104-0000-0000-5f784c9977b5.20.28772")
var batteryLevel: Int = 0
device.connection {
    batteryLevel = device.get(BatteryService.level, timeout: .seconds(10)).asInteger
    guard batteryLevel.hasError == false else { return }
    if let level = batteryLevel, level > 15 {
        self.batteryStatus = "Battery at \(level)"
    } else {
        self.batteryStatus = "Battery level low"
    }
}.then {
    self.showBatteryNotification(for: batteryLevel)
}
```

If you wish a specific action to always be run regardless of the result, you can use `always`:

```swift
let device = XYFinderDeviceFactory.build(from: "xy:ibeacon:a44eacf4-0104-0000-0000-5f784c9977b5.20.28772")
var batteryLevel: Int = 0
device.connection {
    batteryLevel = device.get(BatteryService.level, timeout: .seconds(10)).asInteger
    guard batteryLevel.hasError == false else { return }
    if let level = batteryLevel, level > 15 {
        self.batteryStatus = "Battery at \(level)"
    } else {
        self.batteryStatus = "Battery level low"
    }
}.then {
    self.showBatteryNotification(for: batteryLevel)
}.always {
    self.updateView()
}
```

## Services

The library provides three types of communication with a Bluetooth device, `get`, `set`, and `notify`. These operate on the characteristic of a GATT service, which is defined with the `XYServiceCharacteristicType` protocol. Add a new service by creating an enumeration that implements this protocol:

```swift
public enum MyService: String, XYServiceCharacteristic {

    public var serviceUuid: CBUUID { return MyService.serviceUuid }

    case level

    public var characteristicUuid: CBUUID {
        return BatterySeMyServicervice.uuids[self]!
    }

    public var characteristicType: XYServiceCharacteristicType {
        return .integer
    }

    public var displayName: String {
        return "My Level"
    }

    private static let serviceUuid = CBUUID(string: "0000180F-0000-1000-8000-00805F9B34FB")

    private static let uuids: [MyService: CBUUID] = [
        .level: CBUUID(string: "00002a19-0000-1000-8000-00805f9b34fb")
    ]

    public static var values: [XYServiceCharacteristic] = [
        level
    ]
}
```

## Operation Results

The `XYBluetoothResult` class wraps the data received from a `get` call and allows data to be passed to a `get` service call. The `XYBluetoothResult` allows for access to the raw data, as well as the convenience methods `asInteger`, `asString` and `asByteArray`. Any error information is available in `error` as an `XYFinderBluetoothError`.

## Device Event Notifications

When a connected device changes state or an operation is performed (such as pressing the button on an XY4+) a `XYFinderEvent` notification is sent out via the `XYFinderDeviceEventManager`. You can subscribe to these events as shown here:

```swift
self.subscriptionUuid = XYFinderDeviceEventManager.subscribe(to: [.buttonPressed]) { event in
    switch event {
    case .buttonPressed(let device, _):
        guard let currentDevice = self.selectedDevice, currentDevice == device else { return }
        self.buttonPressed(on: device)
    default:
        break
    }
}
```

The result of the `subscribe` call is a subscription UUID that you can use to unsubscribe from further notifcations:

```swift
XYFinderDeviceEventManager.unsubscribe(to: [.buttonPressed], referenceKey: self.subscriptionUuid)
```

## Smart Scan

The `XYSmartScan` singleton can be used to range and monitor for XY Finder devices. When using the library in an iOS application, it will range for devices in a particular XY Finder device family when put into foreground mode using `switchToForeground`, and use lower power monitoring when placed into backgound mode with `switchToBackground`. The macOS library will locate devices using the `CBCentralManager.scanForPeripherals` method.

## Samples

The library comes with two sample projects, one for macOS and one for iOS. The macOS sample requires you to run `carthage update` in the project directory. The iOS sample requires either `pod install` or `carthage update` to be run. 

## License

See the [LICENSE.md](LICENSE) file for license details.

## Credits

Made with 🔥and ❄️ by [XY - The Persistent Company](https://www.xy.company)
