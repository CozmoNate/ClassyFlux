Pod::Spec.new do |s|
  s.name             = 'ClassyFlux'
  s.version          = '1.4.2'
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

  s.subspec 'Core' do |core|
    core.source_files = [
      'Flux/FluxAction.swift',
      'Flux/FluxDispatcher.swift',
      'Flux/FluxMiddleware.swift',
      'Flux/FluxRepository.swift',
      'Flux/FluxState.swift',
      'Flux/FluxWorker.swift']
  end

  s.subspec 'SwiftUI' do |swiftui|
    swiftui.ios.deployment_target = '13.0'
    swiftui.osx.deployment_target = '10.15'
    swiftui.dependency 'ClassyFlux/Core'
    swiftui.source_files = [
      'Flux/FluxStore.swift',
      'Flux/FluxView.swift']
  end

  s.default_subspec = 'Core'

end
