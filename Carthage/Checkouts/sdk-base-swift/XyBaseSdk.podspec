Pod::Spec.new do |s|
  s.name = 'XyBaseSdk'
  s.version = '1.0.1'
  s.license = { :type => 'LGPL3', :file => 'LICENSE' }
  s.summary = 'XY Base Swift Library'
  s.homepage = 'https://github.com/xyoraclenetwork/sdk-base-swift'
  s.social_media_url = 'https://twitter.com/xyodevs'
  s.authors = { 'XYO Network' => 'developers@xyo.network' }
  s.source = { :git => "https://github.com/xyoraclenetwork/sdk-base-swift.git", :tag => "#{s.version}" }
  s.documentation_url = 'https://github.com/xyoraclenetwork/sdk-base-swift'
  s.swift_version = '5.0'

  s.ios.deployment_target = '11.0'

  s.source_files = 'Source/**/*.{swift}'
  
  s.dependency 'PromisesSwift'
end