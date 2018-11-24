#
# Be sure to run `pod lib lint PingPong.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
    s.name = "PingPong"
    s.version = "0.5"
    s.summary = "A Beloved Robot framework that supports background, foreground, and offline json document syncing"
    s.homepage = "https://github.com/BelovedRobot/PingPong"
    s.license = "MIT"
    s.authors = { "Zane Kellog" => "zane@belovedrobot.com", "Juan Pereira" => "juan@belovedrobot.com", "Humayun Haroon" => "humayunharoon@gmail.com" }
    s.platform = :ios, "11.0"
    s.source = { :git => 'https://github.com/BelovedRobot/PingPong.git', :tag => '0.5' }
    s.ios.deployment_target = '11.0'
    s.source_files = 'PingPong/Classes/**/*'
    s.resource_bundles = {
        'PingPong' => ['PingPong/Assets/*']
    }
    s.dependency 'SwiftyJSON', '~> 4.2.0'
    s.dependency 'Alamofire', '~> 4.7.3'
    s.dependency 'FMDB'
    s.pod_target_xcconfig = { 'SWIFT_VERSION' => '4.2' }
    s.swift_version = '4.2'
end
