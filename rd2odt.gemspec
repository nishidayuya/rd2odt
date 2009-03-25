Gem::Specification.new do |s|
  s.name = "rd2odt"
  s.version = "0.0.0"

  s.authors = "Yuya.Nishida."
  s.email = "yuyaAT@ATj96DOT.DOTorg"

  s.rubyforge_project = s.name
  s.homepage = "http://rubyforge.org/projects/#{s.name}/"
  s.platform = Gem::Platform::RUBY
  s.required_ruby_version = ">= 1.8.6"
  s.summary = "RD(Ruby Document) to OpenDocument converter."
  s.requirements << "rubyzip"
  s.require_path = "lib"
  # s.autorequire = "rake"
  # s.has_rdoc = true
  # s.extra_rdoc_files = ["README"]
  s.executable = "rd2odt"
  s.files = FileList["bin/rd2odt",
                     "lib/**/*.rb",
                     "doc/**/[a-z]*.rd*",
                     "doc/**/*.odt",
                     "test/**/*.rb",
                     "rd2odt.gemspec",
                     "Rakefile",
                     "LICENSE",
                     "FUTURE",
                     "setup.rb"]
  s.description = <<EOF
#{s.summary}
EOF
end

# Editor settings
# - Emacs -
# local variables:
# mode: Ruby
# end:
