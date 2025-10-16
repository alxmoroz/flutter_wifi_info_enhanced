#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint wifi_info_plus.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'wifi_info_plus'
  s.version          = '1.0.0'
  s.summary          = 'Flutter plugin for getting WiFi information with improved iOS support'
  s.description      = <<-DESC
Flutter plugin for getting WiFi information with improved iOS support
                       DESC
  s.homepage         = 'https://github.com/alxmoroz/wifi_info_plus_flutter'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Alexandr Moroz' => 'alexandrmoroz@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '11.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
