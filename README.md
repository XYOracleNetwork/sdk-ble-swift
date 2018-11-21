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
Talking to a Bluetooth device using Core Bluetooth is a drag. The developer needs to monitor delegate methods from `CBCentral` and `CBPeripheral` with no clear path to handling multiple connections. Tutorial code for Core Bluetooth is often a chain of use-case specific method calls from within these delegates, which can lead to frustration when trying to apply the code in a more resusable pattern. Add in the often upredictable nature of Bluetooth and the associated hardware and it 

The XyBleSdk provides a simple interface to communicating with an XY Finder or other Bluetooth device. Let's take a look at an example for an XY Finder device:

```swift
let device = XYFinderDeviceFactory.build(from: "xy:ibeacon:a44eacf4-0104-0000-0000-5f784c9977b5.20.28772")
device.connection {
    let batteryLevel = device.get(BatteryService.level, timeout: .seconds(10))
    if batteryLevel > 15 {
        self.batteryStatus = "\(batteryLevel)"
    } else {
        self.batteryStatus = "Battery level low"
    }
}
```

The `XYFinderDeviceFactory` can build a device from a string, peripheral, etc. The calls made inside the `connection` closure are run one at a time in order. Using `connection` manages wrangling `CBCentral` and the associated `CBPeripheral` delegates, ensuring you have a connection before trying the GATT operation(s) in the block.

Once all the operations have completed, you can use `then` if there are post actions you wish to run:

```swift
let device = XYFinderDeviceFactory.build(from: "xy:ibeacon:a44eacf4-0104-0000-0000-5f784c9977b5.20.28772")
device.connection {
    let batteryLevel = device.get(BatteryService.level, timeout: .seconds(10))
}.then {

}
```

You can check for an error from your operations by using `catch`:

```swift
let device = XYFinderDeviceFactory.build(from: "xy:ibeacon:a44eacf4-0104-0000-0000-5f784c9977b5.20.28772")
device.connection {
    let batteryLevel = device.get(BatteryService.level, timeout: .seconds(10))
}.then {

}.catch { error in

}
```

If you wish a specific action to always be run regardless of the result, you can use `always`:

```swift
let device = XYFinderDeviceFactory.build(from: "xy:ibeacon:a44eacf4-0104-0000-0000-5f784c9977b5.20.28772")
device.connection {
    let batteryLevel = device.get(BatteryService.level, timeout: .seconds(10))
}.then {

}.catch { error in

}.always {

}
```


## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Author

Darren Sutherland, darren@xyo.network

## License

XyBleSdk is available under the MIT license. See the LICENSE file for more info.
