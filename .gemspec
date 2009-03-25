Gem::Specification.new do |s|
  s.authors = "Yuya.Nishida."
  s.email = "yuyaAT@ATj96DOT.DOTorg"
  s.rubyforge_project = "rd2odt"
  s.homepage = "http://rubyforge.org/projects/rd2odt/"
  s.platform = Gem::Platform::RUBY
  s.required_ruby_version = ">= 1.8.6"
  s.summary = "RD(Ruby Document) to OpenDocument converter."
  s.name = "rd2odt"
  s.version = "0.0.0"
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
                     ".gemspec",
                     "Rakefile",
                     "LICENSE",
                     "FUTURE",
                     "setup.rb"]
  s.description = <<EOF
RD2ODT is a converter for RD => OpenDocument format.
EOF
end

# Editor settings
# - Emacs -
# local variables:
# mode: Ruby
# end:
