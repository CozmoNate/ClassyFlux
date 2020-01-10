Pod::Spec.new do |s|
  s.name             = 'ClassyFlux'
  s.version          = '1.19.4'
  s.summary          = 'Flux implementation on Swift'
  s.homepage         = 'https://github.com/kzlekk/ClassyFlux'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Natan Zalkin' => 'natan.zalkin@me.com' }
  s.source           = { :git => 'https://github.com/kzlekk/ClassyFlux.git', :tag => "#{s.version}" }
  s.module_name      = 'ClassyFlux'
  s.swift_version    = '5.0'

  s.ios.deployment_target = '11.0'
  s.osx.deployment_target = '10.14'
  s.watchos.deployment_target = '5.0'
  s.tvos.deployment_target = '12.0'

  s.dependency 'ResolverContainer'

  s.source_files = [
      'Flux/FluxAction.swift',
      'Flux/FluxAggregator.swift',
      'Flux/FluxIterator.swift',
      'Flux/FluxDispatcher.swift',
      'Flux/FluxMiddleware.swift',
      'Flux/FluxStore.swift',
      'Flux/FluxWorker.swift',
      'Flux/FluxBackgroundDispatcher.swift',
      'Flux/FluxInteractiveDispatcher.swift',
      'Flux/FluxSynchronousDispatcher.swift',]

end
