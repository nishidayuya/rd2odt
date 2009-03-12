# -*- coding: utf-8 -*-

$top_srcdir = File.join(File.dirname(__FILE__), "..")
$LOAD_PATH << File.join($top_srcdir, "lib")

$KCODE = "u" if RUBY_VERSION < "1.8.9"

require "rd2odt"
