Pod::Spec.new do |s|
  s.name         = "PingPong"
  s.version      = "0.3.0"
  s.summary      = "A Beloved Robot framework that supports background, foreground, and offline json document syncing"
  s.homepage     = "https://github.com/BelovedRobot/PingPong"
  s.license      = "MIT"
  s.authors             = { "Zane Kellog" => "zane@belovedrobot.com", "Juan Pereira" => "juan@belovedrobot.com" }
  s.social_media_url   = "http://twitter.com/Belovedrobot"
  s.platform     = :ios, "10.0"
  s.source       = { :git => 'https://github.com/BelovedRobot/PingPong', :tag => 'v0.3.0' }
  s.source_files  = "PingPong", "PingPong/*.{h,m,swift}"
  s.resource_bundles = {
    'PingPong' => [
        'PingPong/**/*.sql'
    ]
  }

  s.dependency 'SwiftyJSON'
  s.dependency 'Alamofire', '~> 4.4'
  s.dependency 'FMDB' 
  s.pod_target_xcconfig = { 'SWIFT_VERSION' => '3' }
end
