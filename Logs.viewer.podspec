Pod::Spec.new do |s|
    s.name             = 'Logs.viewer'
    s.version          = '1.0.2'
    s.summary          = 'A library for debugging iOS applications in browser'
    s.homepage         = 'https://github.com/sergeymild/Logs.viewer'
    s.license          = { type: 'MIT', file: 'LICENSE' }
    s.author           = { 'Sergey Mild' => 'https://github.com/sergeymild' }
    s.source           = { git: 'https://github.com/sergeymild/Logs.viewer.git', tag: s.version.to_s }
    s.module_name      = 'LogsViewer'

    s.ios.deployment_target = '11.0'
    s.source_files = 'Sources/**/*.swift'
    s.resource_bundles = { 'com.sergeymild.LogsViewer.assets' => ['Sources/**/*.{js,css,ico,html}'] }

    s.dependency 'Swifter'
    s.dependency 'Socket.IO-Client-Swift', '~> 15.2.0'
end
