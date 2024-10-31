Pod::Spec.new do |spec|
  spec.name = 'CombineCoreBluetooth'
  spec.version = '0.8.0'
  spec.summary = 'A wrapper API for CoreBluetooth using Combine Publishers.'
  spec.homepage = 'https://github.com/StarryInternet/CombineCoreBluetooth'
  spec.author = { 'Kevin Lundberg' => 'klundberg@starry.com' }
  spec.license = { :type => 'MIT' }

  spec.ios.deployment_target = '13.0'
  spec.osx.deployment_target = '11.0'
  spec.tvos.deployment_target = '13.0'
  spec.watchos.deployment_target = '6.0'
  spec.visionos.deployment_target = '1.0'

  spec.swift_version = '5.9'
  spec.source = { :git => 'https://github.com/StarryInternet/CombineCoreBluetooth.git', :tag => "#{spec.version}" }
  spec.source_files = 'Sources/CombineCoreBluetooth/**/*.swift'

  spec.frameworks = 'Combine', 'CoreBluetooth'
end
