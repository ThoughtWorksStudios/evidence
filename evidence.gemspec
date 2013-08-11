Gem::Specification.new do |s|
  s.name = 'evidence'
  s.version = '0.0.2'
  s.summary = 'Log Analysis Tool'
  s.license = 'MIT'
  s.authors = ["Xiao Li", 'Sheroy Marker']
  s.email = ['swing1979@gmail.com', 'smarker@thoughtworks.com']
  s.homepage = 'https://github.com/ThoughtWorksStudios/evidence'

  s.add_development_dependency('rake')

  s.files = ['README.md']
  s.files += Dir['lib/**/*.rb']
  s.files += Dir['examples/*']
end
