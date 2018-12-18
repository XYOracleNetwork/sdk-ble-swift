#
# Be sure to run `pod lib lint XyBleSdk.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name = 'XyBleSdk'
  s.version = '0.1.0'
  s.license = { :type => 'MIT', :file => 'LICENSE' }
  s.summary = 'Swift BLE SDK for app developers who want better bluetooth performance'
  s.homepage = 'https://github.com/XYOracleNetwork/sdk-ble-swift'
  s.social_media_url = 'https://twitter.com/xyodevs'
  s.authors = { 'XY - The Persistent Company' => 'darren@xyo.network' }
  s.source = { :git => 'https://github.com/XYOracleNetwork/sdk-ble-swift.git', :tag => s.version }
  s.documentation_url = 'https://github.com/XYOracleNetwork/sdk-ble-swift'
  s.swift_version = '4.2'

  s.ios.deployment_target = '11.0'

  s.source_files = 'XyBleSdk/Classes/**/*'
  
  s.dependency 'PromisesSwift', '~> 1.2.3'
end