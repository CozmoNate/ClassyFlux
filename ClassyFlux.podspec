Pod::Spec.new do |s|
  s.name             = 'ClassyFlux'
  s.version          = '1.4.0'
  s.summary          = 'Flux implementation on Swift'
  s.homepage         = 'https://github.com/kzlekk/ClassyFlux'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Natan Zalkin' => 'natan.zalkin@me.com' }
  s.source           = { :git => 'https://github.com/kzlekk/ClassyFlux.git', :tag => "#{s.version}" }
  s.module_name      = 'Flux'
  s.swift_version    = '5.0'

  s.ios.deployment_target = '11.0'
  s.osx.deployment_target = '10.14'

  s.dependency 'CustomOperation'
  s.dependency 'ResolverContainer'
  
  s.source_files = 'Flux/*.swift'

end
