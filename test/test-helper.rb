# -*- coding: utf-8 -*-

$top_srcdir = File.join(File.dirname(__FILE__), "..")
$LOAD_PATH << File.join($top_srcdir, "lib")

$KCODE = "u" if RUBY_VERSION < "1.9.0"

require "rd2odt"
require "tempfile"

module XmlMatchers
  class BeSameAsThisXml
    def initialize(expected)
      @expected = expected
      if String === expected || Symbol === expected
        @expected_dom = to_dom(expected.to_s)
      end
    end

    def matches?(actual)
      @actual = actual
      if String === actual || Symbol === actual
        @actual_dom = to_dom(actual.to_s)
      end
      return expected_dom.to_s == actual_dom.to_s
    end

    def failure_message
      return "difference: #{diff}"
    end

    alias negative_failure_message failure_message

    private

    DOM_PREFIX = <<EOF
<?xml version='1.0' encoding='UTF-8'?>

<office:document-content xmlns:script='urn:oasis:names:tc:opendocument:xmlns:script:1.0' xmlns:oooc='http://openoffice.org/2004/calc' xmlns:number='urn:oasis:names:tc:opendocument:xmlns:datastyle:1.0' xmlns:dr3d='urn:oasis:names:tc:opendocument:xmlns:dr3d:1.0' xmlns:math='http://www.w3.org/1998/Math/MathML' xmlns:dom='http://www.w3.org/2001/xml-events' xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance' xmlns:text='urn:oasis:names:tc:opendocument:xmlns:text:1.0' xmlns:svg='urn:oasis:names:tc:opendocument:xmlns:svg-compatible:1.0' xmlns:ooo='http://openoffice.org/2004/office' xmlns:xforms='http://www.w3.org/2002/xforms' xmlns:table='urn:oasis:names:tc:opendocument:xmlns:table:1.0' xmlns:meta='urn:oasis:names:tc:opendocument:xmlns:meta:1.0' xmlns:form='urn:oasis:names:tc:opendocument:xmlns:form:1.0' xmlns:field='urn:openoffice:names:experimental:ooxml-odf-interop:xmlns:field:1.0' xmlns:draw='urn:oasis:names:tc:opendocument:xmlns:drawing:1.0' office:version='1.1' xmlns:office='urn:oasis:names:tc:opendocument:xmlns:office:1.0' xmlns:xsd='http://www.w3.org/2001/XMLSchema' xmlns:xlink='http://www.w3.org/1999/xlink' xmlns:fo='urn:oasis:names:tc:opendocument:xmlns:xsl-fo-compatible:1.0' xmlns:dc='http://purl.org/dc/elements/1.1/' xmlns:style='urn:oasis:names:tc:opendocument:xmlns:style:1.0' xmlns:ooow='http://openoffice.org/2004/writer' xmlns:chart='urn:oasis:names:tc:opendocument:xmlns:chart:1.0'>


EOF

    DOM_SUFFIX = <<EOF


</office:document-content>
EOF

    def expected_dom
      return (@expected_dom ||= to_dom(RD2ODT.ah_to_xml(@expected)))
    end

    def actual_dom
      return (@actual_dom ||= to_dom(RD2ODT.ah_to_xml(@expected)))
    end

    def to_dom(s)
      root = REXML::Document.new(DOM_PREFIX + s + DOM_SUFFIX)
      result = root[2][1] # `result' is only XML from `s'.
      return result
    end

    def diff
      Tempfile.open("rd2odt-test") do |expected_file|
        Tempfile.open("rd2odt-test") do |actual_file|
          expected_file.puts(expected_dom.to_s)
          expected_file.close
          actual_file.puts(actual_dom.to_s)
          actual_file.close

          result = `docdiff --utf8 --char --tty #{expected_file.path} #{actual_file.path}`
          return result
        end
      end
    end
  end

  def be_same_as_this_xml(expected)
    return BeSameAsThisXml.new(expected)
  end
end
