require "rake"
require "rake/gempackagetask"
require "spec/rake/spectask"

task :default => [:spec, :init_gem_spec, :package]

Spec::Rake::SpecTask.new do |t|
  t.spec_files = FileList["test/**/*-spec.rb"]
  t.libs << "lib"
end

task :init_gem_spec do
  spec = Gem::Specification.new do |s|
    s.authors = "yuya"
    s.email = "yuyaAT@ATj96DOT.DOTorg"
    s.platform = Gem::Platform::RUBY
    s.required_ruby_version = ">= 1.8.6"
    s.summary = "RD(Ruby Document) to OpenDocument converter."
    s.name = "rd2odt"
    s.version = "0.0.0"
    s.requirements << "rubyzip"
    s.require_path = "lib"
    s.autorequire = "rake"
    s.executable = "rd2odt"
    s.files = FileList["bin/rd2odt",
                       "lib/**/*.rb",
                       "doc/**/[a-z]*.rd*",
                       "doc/**/*.odt",
                       "test/**/*.rb",
                       "Rakefile",
                       "LICENSE",
                       "setup.rb"]
    s.description = <<EOF
RD2ODT is a converter for RD => OpenDocument format.
EOF
  end

  Rake::GemPackageTask.new(spec) do |pkg|
    pkg.need_zip = true
    pkg.need_tar_gz = true
  end
end
