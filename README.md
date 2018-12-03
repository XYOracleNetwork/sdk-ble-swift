[logo]: https://www.xy.company/img/home/logo_xy.png

![logo]

# sdk-ble-ios
A Bluetooth library, primarily for use with XY Finder devices but can be implemented to communicate with any Bluetooth device, with monitoring capability if the device emits an iBeacon signal. The library is designed to aleviate the delegate-based interaction with Core Bluetooth classes and presents a straightforward API, allowing the developer to write asyncronous code in a syncronous manner. The libray utlizes the [Google Promises](https://github.com/google/promises) library as a dependency.

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

You can check for an error from your operations by using `catch`. The error is of type `XYFinderBluetoothError`.

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
}.catch { error in
    self.showErrorNotification(for: error)
}
```

If you wish a specific action to always be run regardless of the result, you can use `always`:

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
}.catch { error in
    self.showErrorNotification(for: error)
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

The `XYBluetoothResult` class wraps the data received from a `get` call and allows data to be passed to a `get` service call. The `XYBluetoothResult` allows for access to the raw data, as well as the convenience methods `asInteger`, `asString` and `asByteArray`. Any error information is available in `error` as an `XYBluetoothError`.

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first. This project is a simple XY locator scanner, allowing you to view the characteristics of the devices various services.

## Author

Darren Sutherland, darren@xyo.network

## License

XyBleSdk is available under the MIT license. See the LICENSE file for more info.

<br><hr><br>
<p align="center">Made with  ❤️  by [<b>XY - The Persistent Company</b>] (https://xy.company)</p>
