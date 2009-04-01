require "rake"
require "rake/gempackagetask"
require "spec/rake/spectask"
require "rake/rdoctask"

task :default => [:clean, :spec, :init_gem_spec, :package]

desc "Clean up generated files and directories"
task :clean do
  rm_rf "pkg"
  rm_rf FileList["doc/**/*.rd.odt",
                 "doc/**/*.rd.ja.odt"]
end

Spec::Rake::SpecTask.new do |t|
  t.spec_files = FileList["test/**/*-spec.rb"]
  t.libs << "lib"
end

Rake::RDocTask.new do |t|
  t.main = "README"
  t.rdoc_files.include("README")
  t.rdoc_files.include("FUTURE")
  t.rdoc_files.include("NEWS")
  t.rdoc_files.include("LICENSE")
end

desc "Build packages"
task :init_gem_spec do
  s = File.read("rd2odt.gemspec").untaint
  spec = nil
  Thread.start {
    $SAFE = 2
    spec = Module.new.module_eval(s)
  }.join
  Rake::GemPackageTask.new(spec) do |pkg|
    pkg.need_zip = true
    pkg.need_tar_gz = true
  end
end

# Editor settings
# - Emacs -
# local variables:
# mode: Ruby
# end:
