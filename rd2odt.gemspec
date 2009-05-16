Gem::Specification.new do |s|
  s.name = "rd2odt"
  s.version = "0.1.0"

  s.authors = "Yuya.Nishida."
  s.email = "yuyaAT@ATj96DOT.DOTorg"

  s.rubyforge_project = s.name
  s.homepage = "http://rubyforge.org/projects/#{s.name}/"
  s.platform = Gem::Platform::RUBY
  s.required_ruby_version = ">= 1.8.7"
  s.rubygems_version = ">= 1.3.0"
  s.requirements << "rubyzip"
  s.require_paths = ["lib", "lib/rd2odt/rdtool"]
  # s.autorequire = "rake"
  # s.has_rdoc = true
  # s.extra_rdoc_files = ["README"]
  s.executable = "rd2odt"

  s.summary = "RD(Ruby Document) to OpenDocument converter."
  s.description = <<EOF
#{s.summary}
EOF

  s.files = ["bin/rd2odt",

             # "lib/**/*.rb",
             "lib/rd2odt.rb",
             "lib/rd2odt/rdtool/NOTICE.rd2odt",
             "lib/rd2odt/rdtool/README.rd",
             "lib/rd2odt/rdtool/README.rd.ja",
             "lib/rd2odt/rdtool/rd/block-element.rb",
             "lib/rd2odt/rdtool/rd/complex-list-item.rb",
             "lib/rd2odt/rdtool/rd/desclist.rb",
             "lib/rd2odt/rdtool/rd/document-struct.rb",
             "lib/rd2odt/rdtool/rd/element.rb",
             "lib/rd2odt/rdtool/rd/filter.rb",
             "lib/rd2odt/rdtool/rd/inline-element.rb",
             "lib/rd2odt/rdtool/rd/labeled-element.rb",
             "lib/rd2odt/rdtool/rd/list.rb",
             "lib/rd2odt/rdtool/rd/loose-struct.rb",
             "lib/rd2odt/rdtool/rd/methodlist.rb",
             "lib/rd2odt/rdtool/rd/output-format-visitor.rb",
             "lib/rd2odt/rdtool/rd/package.rb",
             "lib/rd2odt/rdtool/rd/parser-util.rb",
             "lib/rd2odt/rdtool/rd/rbl-file.rb",
             "lib/rd2odt/rdtool/rd/rbl-suite.rb",
             "lib/rd2odt/rdtool/rd/rd-struct.rb",
             "lib/rd2odt/rdtool/rd/rd2html-lib.rb",
             "lib/rd2odt/rdtool/rd/rd2html-opt.rb",
             "lib/rd2odt/rdtool/rd/rd2man-lib.rb",
             "lib/rd2odt/rdtool/rd/rd2rdo-lib.rb",
             "lib/rd2odt/rdtool/rd/rd2rmi-lib.rb",
             "lib/rd2odt/rdtool/rd/rdblockparser.tab.rb",
             "lib/rd2odt/rdtool/rd/rdfmt.rb",
             "lib/rd2odt/rdtool/rd/rdinlineparser.tab.rb",
             "lib/rd2odt/rdtool/rd/rdvisitor.rb",
             "lib/rd2odt/rdtool/rd/reference-resolver.rb",
             "lib/rd2odt/rdtool/rd/search-file.rb",
             "lib/rd2odt/rdtool/rd/tree.rb",
             "lib/rd2odt/rdtool/rd/version.rb",
             "lib/rd2odt/rdtool/rd/visitor.rb",

             # "doc/**/[a-z]*.rd*",
             "doc/sample.rd.ja",
             "doc/sample.rd.ja.ott",
             "doc/sample.rd.ja.pdf",
             "doc/sample/body-text.rd",
             "doc/sample/enum-list-over-headline-multi-level.rd",
             "doc/sample/enum-list-over-headline.rd",
             "doc/sample/enum-list-over-item-list-multi-level-2.rd",
             "doc/sample/enum-list-over-item-list-multi-level.rd",
             "doc/sample/enum-list-over-item-list.rd",
             "doc/sample/headline.rd",
             "doc/sample/include.rd",
             "doc/sample/list.rd",
             "doc/sample/multi-paragraph.rd",
             "doc/sample/verbatim.rd",
             "doc/specification.ja.rd",

             # "doc/**/*.odt"
             "doc/sample/include-file-figure.odt",
             "doc/sample/include-file-ole-object.odt",
             "doc/sample/include-file-original-styled-text.odt",
             "doc/sample/include-file-shape.odt",
             "doc/sample/include-file-simple-styled-text.odt",
             "doc/sample/include-file-simple-text.odt",
             "doc/sample/include-file-table.odt",
             "doc/sample/page-break.odt",

             # "test/**/*.rb",
             "test/functional/rd2odt-spec.rb",
             "test/test-helper.rb",
             "test/unit/rd2odt-spec.rb",
             "rd2odt.gemspec",
             "Rakefile",
             "README",
             "FUTURE",
             "NEWS",
             "LICENSE",
             "setup.rb"]
end

# Editor settings
# - Emacs -
# local variables:
# mode: Ruby
# end:
