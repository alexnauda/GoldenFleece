Pod::Spec.new do |s|
  s.name         =  'GoldenFleece'
  s.version      =  '0.2'
  s.summary      =  'On a quest for a better JSON API'
  s.homepage     =  'https://github.com/alexnauda/GoldenFleece'
  s.author       =  { 'Alex Nauda' => 'alex@alexnauda.com' }
  s.source       =  { :git => 'https://github.com/alexnauda/GoldenFleece', :tag => 'v0.2' }
  s.license      =  'Apache License, Version 2.0'
  
  # Platform setup
  s.requires_arc = true
  s.ios.deployment_target = '5.0'
  s.osx.deployment_target = '10.7'

  # Dependencies
  s.dependency       'AFNetworking', '~> 1.2.0'
  s.dependency       'JSONKit', '~> 1.5pre'
  s.dependency       'NSObject-AutomagicCoding', '1.1.1.alexnauda' # https://github.com/alexnauda/Specs-internal.git
  s.dependency       'NSDate+Helper', '~> 0.0.1'

  s.source_files = '**/*.{h,m}'
end
