#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_digital_id_darwin.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_digital_id_darwin'
  s.version          = '0.1.0'
  s.summary          = 'iOS and macOS implementation of flutter_digital_id.'
  s.description      = <<-DESC
iOS and macOS (unified darwin) implementation of the flutter_digital_id plugin.
                       DESC
  s.homepage         = 'https://github.com/jameshancock/flutter_digital_id'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'James Hancock' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Sources/flutter_digital_id_darwin/**/*'
  s.public_header_files = 'Sources/flutter_digital_id_darwin/**/*.h'
  s.dependency 'Flutter'

  s.ios.deployment_target = '16.5'
  s.osx.deployment_target = '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.9'
end
