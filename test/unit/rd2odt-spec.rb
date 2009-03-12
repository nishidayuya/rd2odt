# -*- coding: utf-8 -*-

require File.join(File.dirname(__FILE__), "..", "test-helper")

describe RD2ODT, "ah_to_xml" do
  # not supported.
  # it "returns empty string if empty array" do
  #   RD2ODT.ah_to_xml([]).should == nil
  # end

  it "returns xml document" do
    RD2ODT.ah_to_xml([:br]).should == "<br />"
    RD2ODT.ah_to_xml([:text__p]).should == "<text:p />"
    RD2ODT.ah_to_xml([:text__style_name]).should == "<text:style-name />"
    RD2ODT.ah_to_xml([:text__sequence_decl,
                      {
                        :text__display_outline_level => "0",
                        :text__name => "Table",
                      },
                     ]).should ==
      '<text:sequence-decl text:display-outline-level="0" text:name="Table" />'
    RD2ODT.ah_to_xml([:text__p, "this is a pen."]).should ==
      "<text:p>this is a pen.</text:p>"
    RD2ODT.ah_to_xml([:text__p, '&"><']).should ==
      "<text:p>&amp;&quot;&gt;&lt;</text:p>"
    RD2ODT.ah_to_xml([:text__p,
                      %Q'Lo<text:s text:c="2" />ok&gt;'.to_sym]).should ==
      %Q'<text:p>Lo<text:s text:c="2" />ok&gt;</text:p>'
    RD2ODT.ah_to_xml([:text__p,
                      {:text__style_name => "Text_20_body"},
                      "this is a pen.",
                     ]).should ==
      '<text:p text:style-name="Text_20_body">this is a pen.</text:p>'
    RD2ODT.ah_to_xml([:office__text,
                      [:text__p,
                       {:text__style_name => "Text_20_body"},
                       "this is a pen.",
                      ],
                     ]).should ==
      <<EOF.gsub(/\n\z/, "")
<office:text>
 <text:p text:style-name="Text_20_body">this is a pen.</text:p>
</office:text>
EOF
    RD2ODT.ah_to_xml([:office__body,
                      {
                        :abc__def_ghi => "123",
                        :jkl_mno__pqr => "456",
                      },
                      [:office__text,
                       [:text__p,
                        {:text__style_name => "Text_20_body"},
                        "this is a pen.",
                       ],
                      ],
                     ]).should ==
      <<EOF.gsub(/\n\z/, "")
<office:body abc:def-ghi="123" jkl-mno:pqr="456">
 <office:text>
  <text:p text:style-name="Text_20_body">this is a pen.</text:p>
 </office:text>
</office:body>
EOF
    RD2ODT.ah_to_xml([
                      [:text__p,
                       {:text__style_name => "Preformatted_20_Text"},
                       "text-1",
                      ],
                      [:text__p,
                       {:text__style_name => "Preformatted_20_Text"},
                       "text-2",
                      ],
                     ]).should ==
      <<EOF.gsub(/\n\z/, "")
<text:p text:style-name="Preformatted_20_Text">text-1</text:p>
<text:p text:style-name="Preformatted_20_Text">text-2</text:p>
EOF
  end
end

def str_to_treat_input_ary(s)
  ary = s.split("\n").map { |l|
    l + "\n"
  }

  # last line does not have "\n" case.
  if !/\n\z/.match(s)
    ary.last.chomp!
  end

  return ary
end

describe RD2ODT, "treat_input" do
  it "adds '=begin' to first line and adds '=end' to last line if both lines is
  not exist." do
    actual_str = <<ACTUAL
foo
bar
ACTUAL
    expected = str_to_treat_input_ary(<<EXPECTED)
=begin
foo
bar
=end
EXPECTED

    actual_1 = str_to_treat_input_ary(actual_str)
    RD2ODT.treat_input(actual_1).should == expected

    actual_2 = str_to_treat_input_ary(actual_str.chomp)
    RD2ODT.treat_input(actual_2).should == expected
  end

  it "does not add '=begin' to first line if it is exist." do
    ary = str_to_treat_input_ary(<<EOF)
foo
=begin
bar
EOF
    RD2ODT.treat_input(ary.dup).should == ary.dup
  end

  it "does not add '=end' to last line if it is exist." do
    ary = str_to_treat_input_ary(<<EOF)
foo
=end
bar
EOF
    RD2ODT.treat_input(ary.dup).should == ary.dup
  end
end

describe RD2ODT::RD2ODTVisitor, "apply_to_DocumentElement" do
  before do
    @visitor = RD2ODT::RD2ODTVisitor.new
  end

  it "returns top level document structure" do
    sub_content = [:text__p,
                   {:text__style_name => "Text_20_body"},
                   "本文",
                  ]
    result = @visitor.apply_to_DocumentElement(nil,
                                               [sub_content,
                                                sub_content])
    result.should ==
      [:office__document_content,
       {
         :xmlns__office => "urn:oasis:names:tc:opendocument:xmlns:office:1.0",
         :xmlns__style => "urn:oasis:names:tc:opendocument:xmlns:style:1.0",
         :xmlns__text => "urn:oasis:names:tc:opendocument:xmlns:text:1.0",
         :xmlns__table => "urn:oasis:names:tc:opendocument:xmlns:table:1.0",
         :xmlns__draw => "urn:oasis:names:tc:opendocument:xmlns:drawing:1.0",
         :xmlns__fo =>
         "urn:oasis:names:tc:opendocument:xmlns:xsl-fo-compatible:1.0",
         :xmlns__xlink => "http://www.w3.org/1999/xlink",
         :xmlns__dc => "http://purl.org/dc/elements/1.1/",
         :xmlns__meta => "urn:oasis:names:tc:opendocument:xmlns:meta:1.0",
         :xmlns__number =>
         "urn:oasis:names:tc:opendocument:xmlns:datastyle:1.0",
         :xmlns__svg =>
         "urn:oasis:names:tc:opendocument:xmlns:svg-compatible:1.0",
         :xmlns__chart => "urn:oasis:names:tc:opendocument:xmlns:chart:1.0",
         :xmlns__dr3d => "urn:oasis:names:tc:opendocument:xmlns:dr3d:1.0",
         :xmlns__math => "http://www.w3.org/1998/Math/MathML",
         :xmlns__form => "urn:oasis:names:tc:opendocument:xmlns:form:1.0",
         :xmlns__script => "urn:oasis:names:tc:opendocument:xmlns:script:1.0",
         :xmlns__ooo => "http://openoffice.org/2004/office",
         :xmlns__ooow => "http://openoffice.org/2004/writer",
         :xmlns__oooc => "http://openoffice.org/2004/calc",
         :xmlns__dom => "http://www.w3.org/2001/xml-events",
         :xmlns__xforms => "http://www.w3.org/2002/xforms",
         :xmlns__xsd => "http://www.w3.org/2001/XMLSchema",
         :xmlns__xsi => "http://www.w3.org/2001/XMLSchema-instance",
         :xmlns__field =>
         "urn:openoffice:names:experimental:ooxml-odf-interop:xmlns:field:1.0",
         :office__version => "1.1",
       },
       [:office__scripts],
       [:office__font_face_decls,
        [:style__font_face,
         {
           :style__name => "さざなみ明朝",
           :svg__font_family => "さざなみ明朝",
           :style__font_family_generic => "roman",
           :style__font_pitch => "variable",
         }],
        [:style__font_face,
         {
           :style__name => "IPAゴシック",
           :svg__font_family => "IPAゴシック",
           :style__font_family_generic => "swiss",
           :style__font_pitch => "variable",
         }],
        [:style__font_face,
         {
           :style__name => "IPAゴシック1",
           :svg__font_family => "IPAゴシック",
           :style__font_family_generic => "system",
           :style__font_pitch => "variable",
         }],
       ], # :office__font_face_decls
       [:office__automatic_styles],
       [:office__body,
        [:office__text,
         [:text__sequence_decls,
          [:text__sequence_decl,
           {
             :text__display_outline_level => "0",
             :text__name => "Illustration",
           }],
          [:text__sequence_decl,
           {
             :text__display_outline_level => "0",
             :text__name => "Table",
           }],
          [:text__sequence_decl,
           {
             :text__display_outline_level => "0",
             :text__name => "Text",
           }],
          [:text__sequence_decl,
           {
             :text__display_outline_level => "0",
             :text__name => "Drawing",
           }],
         ], # :text__sequence_decls
         sub_content,
         sub_content,
        ], # :office__text
       ], # :office__body
      ] # :office__document_content
  end

  it "returns top level document structure with office:automatic-styles" do
    sub_content = [:text__p,
                   {:text__style_name => "Text_20_body"},
                   "本文",
                  ]
    styles = []
    styles << "<a><b/></a>"
    styles << "<c d='e'><f/></c>"
    styles.each do |s|
      @visitor.automatic_styles << REXML::Document.new(s)
    end
    result = @visitor.apply_to_DocumentElement(nil,
                                               [sub_content,
                                                sub_content])
    result.should ==
      [:office__document_content,
       {
         :xmlns__office => "urn:oasis:names:tc:opendocument:xmlns:office:1.0",
         :xmlns__style => "urn:oasis:names:tc:opendocument:xmlns:style:1.0",
         :xmlns__text => "urn:oasis:names:tc:opendocument:xmlns:text:1.0",
         :xmlns__table => "urn:oasis:names:tc:opendocument:xmlns:table:1.0",
         :xmlns__draw => "urn:oasis:names:tc:opendocument:xmlns:drawing:1.0",
         :xmlns__fo =>
         "urn:oasis:names:tc:opendocument:xmlns:xsl-fo-compatible:1.0",
         :xmlns__xlink => "http://www.w3.org/1999/xlink",
         :xmlns__dc => "http://purl.org/dc/elements/1.1/",
         :xmlns__meta => "urn:oasis:names:tc:opendocument:xmlns:meta:1.0",
         :xmlns__number =>
         "urn:oasis:names:tc:opendocument:xmlns:datastyle:1.0",
         :xmlns__svg =>
         "urn:oasis:names:tc:opendocument:xmlns:svg-compatible:1.0",
         :xmlns__chart => "urn:oasis:names:tc:opendocument:xmlns:chart:1.0",
         :xmlns__dr3d => "urn:oasis:names:tc:opendocument:xmlns:dr3d:1.0",
         :xmlns__math => "http://www.w3.org/1998/Math/MathML",
         :xmlns__form => "urn:oasis:names:tc:opendocument:xmlns:form:1.0",
         :xmlns__script => "urn:oasis:names:tc:opendocument:xmlns:script:1.0",
         :xmlns__ooo => "http://openoffice.org/2004/office",
         :xmlns__ooow => "http://openoffice.org/2004/writer",
         :xmlns__oooc => "http://openoffice.org/2004/calc",
         :xmlns__dom => "http://www.w3.org/2001/xml-events",
         :xmlns__xforms => "http://www.w3.org/2002/xforms",
         :xmlns__xsd => "http://www.w3.org/2001/XMLSchema",
         :xmlns__xsi => "http://www.w3.org/2001/XMLSchema-instance",
         :xmlns__field =>
         "urn:openoffice:names:experimental:ooxml-odf-interop:xmlns:field:1.0",
         :office__version => "1.1",
       },
       [:office__scripts],
       [:office__font_face_decls,
        [:style__font_face,
         {
           :style__name => "さざなみ明朝",
           :svg__font_family => "さざなみ明朝",
           :style__font_family_generic => "roman",
           :style__font_pitch => "variable",
         }],
        [:style__font_face,
         {
           :style__name => "IPAゴシック",
           :svg__font_family => "IPAゴシック",
           :style__font_family_generic => "swiss",
           :style__font_pitch => "variable",
         }],
        [:style__font_face,
         {
           :style__name => "IPAゴシック1",
           :svg__font_family => "IPAゴシック",
           :style__font_family_generic => "system",
           :style__font_pitch => "variable",
         }],
       ], # :office__font_face_decls
       [:office__automatic_styles,
        *styles.map { |s|
          s.to_sym
        }
       ],
       [:office__body,
        [:office__text,
         [:text__sequence_decls,
          [:text__sequence_decl,
           {
             :text__display_outline_level => "0",
             :text__name => "Illustration",
           }],
          [:text__sequence_decl,
           {
             :text__display_outline_level => "0",
             :text__name => "Table",
           }],
          [:text__sequence_decl,
           {
             :text__display_outline_level => "0",
             :text__name => "Text",
           }],
          [:text__sequence_decl,
           {
             :text__display_outline_level => "0",
             :text__name => "Drawing",
           }],
         ], # :text__sequence_decls
         sub_content,
         sub_content,
        ], # :office__text
       ], # :office__body
      ] # :office__document_content
  end
end

describe RD2ODT::RD2ODTVisitor, "apply_to_StringElement" do
  before do
    @visitor = RD2ODT::RD2ODTVisitor.new
  end

  it "returns text:p element" do
    element = RD::StringElement.new("本文\n")
    result = @visitor.apply_to_StringElement(element)
    result.should == "本文"
  end

  it "remove \\r and \\n charactor" do
    element = RD::StringElement.new("本文1\n本文2\n本文3\n")
    result = @visitor.apply_to_StringElement(element)
    result.should == "本文1本文2本文3"

    element = RD::StringElement.new("本文1\r\n本文2\r\n本文3\r\n")
    result = @visitor.apply_to_StringElement(element)
    result.should == "本文1本文2本文3"
  end
end

describe RD2ODT::RD2ODTVisitor, "apply_to_TextBlock" do
  before do
    @visitor = RD2ODT::RD2ODTVisitor.new
  end

  it "returns text:p element" do
    sub_content = "本文"
    result = @visitor.apply_to_TextBlock(nil, [sub_content])
    result.should == [:text__p,
                      {:text__style_name => "Text_20_body"},
                      sub_content,
                     ]
  end
end

describe RD2ODT::RD2ODTVisitor, "apply_to_Headline" do
  before do
    @visitor = RD2ODT::RD2ODTVisitor.new
  end

  it "returns text:list element in '=' level without text:continue-numbering when first '='" do
    level = 1
    title = "見出し1"
    element = RD::Headline.new(level)
    element.title << title
    result = @visitor.apply_to_Headline(element, element.title)
    result.should == [:text__list,
                      {:text__style_name => "Numbering_20_2"},
                      [:text__list_item,
                       [:text__p,
                        {:text__style_name => "Heading_20_1"},
                        "見出し1"
                       ],
                      ],
                     ]
    @visitor.continue_numbering_headline.should == true
  end

  it "returns text:list element in '=' level with text:continue-numbering when not first '='" do
    level = 1
    title = "見出し2"
    element = RD::Headline.new(level)
    element.title << title
    @visitor.continue_numbering_headline = true
    result = @visitor.apply_to_Headline(element, element.title)
    result.should == [:text__list,
                      {
                        :text__style_name => "Numbering_20_2",
                        :text__continue_numbering => "true",
                      },
                      [:text__list_item,
                       [:text__p,
                        {:text__style_name => "Heading_20_1"},
                        "見出し2"
                       ],
                      ],
                     ]
    @visitor.continue_numbering_headline.should == true
  end

  it "returns text:list element in '==' level" do
    level = 2
    title = "見出し2"
    element = RD::Headline.new(level)
    element.title << title
    result = @visitor.apply_to_Headline(element, element.title)
    result.should == [:text__list,
                      {
                        :text__style_name => "Numbering_20_2",
                        :text__continue_numbering => "true",
                      },
                      [:text__list_item,
                       [:text__list,
                        {:text__continue_numbering => "true"},
                        [:text__list_item,
                         [:text__p,
                          {:text__style_name => "Heading_20_2"},
                          "見出し2",
                         ],
                        ],
                       ],
                      ],
                     ]
  end

  it "returns text:list element in '===' level" do
    level = 3
    title = "見出し3"
    element = RD::Headline.new(level)
    element.title << title
    result = @visitor.apply_to_Headline(element, element.title)
    result.should == [:text__list,
                      {
                        :text__style_name => "Numbering_20_2",
                        :text__continue_numbering => "true",
                      },
                      [:text__list_item,
                       [:text__list,
                        {:text__continue_numbering => "true"},
                        [:text__list_item,
                         [:text__list,
                          {:text__continue_numbering => "true"},
                          [:text__list_item,
                           [:text__p,
                            {:text__style_name => "Heading_20_3"},
                            "見出し3",
                           ],
                          ],
                         ],
                        ],
                       ],
                      ],
                     ]
  end
end

describe RD2ODT::RD2ODTVisitor, "apply_to_EnumListItem" do
  before do
    @visitor = RD2ODT::RD2ODTVisitor.new
  end

  it "returns text:list-item element" do
    result = @visitor.apply_to_EnumListItem(nil, [:sub_content_1,
                                                  :sub_content_2])
    result.should == [:text__list_item,
                      :sub_content_1,
                      :sub_content_2,
                     ]
  end
end

describe RD2ODT::RD2ODTVisitor, "apply_to_EnumList" do
  before do
    @visitor = RD2ODT::RD2ODTVisitor.new
  end

  it "returns text:list element" do
    result = @visitor.apply_to_EnumList(nil, [:sub_content_1,
                                              :sub_content_2])
    result.should == [:text__list,
                      {
                        :text__style_name => "Numbering_20_1",
                        :text__continue_numbering => "true",
                      },
                      :sub_content_1,
                      :sub_content_2,
                     ]
  end
end

describe RD2ODT::RD2ODTVisitor, "apply_to_ItemListItem" do
  before do
    @visitor = RD2ODT::RD2ODTVisitor.new
  end

  # same as apply_to_EnumListItem
  it "returns text:list-item element" do
    result = @visitor.apply_to_ItemListItem(nil, [:sub_content_1,
                                                  :sub_content_2])
    result.should == [:text__list_item,
                      :sub_content_1,
                      :sub_content_2,
                     ]
  end
end

describe RD2ODT::RD2ODTVisitor, "apply_to_ItemList" do
  before do
    @visitor = RD2ODT::RD2ODTVisitor.new
  end

  it "returns text:list element" do
    result = @visitor.apply_to_ItemList(nil, [:sub_content_1,
                                              :sub_content_2])
    result.should == [:text__list,
                      {:text__style_name => "List_20_1"},
                      :sub_content_1,
                      :sub_content_2,
                     ]
  end
end

describe RD2ODT::RD2ODTVisitor, "apply_to_Verbatim" do
  before do
    @visitor = RD2ODT::RD2ODTVisitor.new
  end

  it "returns text:list element" do
    content_strings = [
                       "This is verbatim element.\n",
                       " " * 2 + "Lo" + " " * 5 + "ok!\n",
                       "\tLo" + "\t\t" + "ok!\n",
                       "In the last line, text:line-break is not exist.\n",
                      ]
    element = RD::Verbatim.new(content_strings)
    result = @visitor.apply_to_Verbatim(element)
    result.should == [:text__p,
                      {:text__style_name => "Preformatted_20_Text"},
                      [
                       "This is verbatim element.",
                       '<text:s text:c="2" />Lo<text:s text:c="5" />ok!<text:line-break /><text:tab />Lo<text:tab /><text:tab />ok!',
                       "In the last line, text:line-break is not exist.",
                      ].join("<text:line-break />").to_sym,
                     ]
  end
end

describe RD2ODT::RD2ODTVisitor, "apply_to_Include" do
  before do
    class Time
      class << self
        alias orig_now now

        def now
          return Time.mktime(2008, 12, 30, 12, 34, 56, 78901)
        end
      end
    end

    @name_prefix = sprintf("rd2odt:%d:%06d:%d:",
                           Time.now.tv_sec, Time.now.tv_usec, 1)

    @visitor = RD2ODT::RD2ODTVisitor.new

    sample_dir_path = File.join($top_srcdir, "doc", "sample")
    tree_mock = Struct.new(:include_paths).new([sample_dir_path])
    @parent_element = Struct.new(:tree).new(tree_mock)
  end

  after do
    class Time
      class << self
        alias now orig_now
      end
    end
  end

  it "includes other document" do
    element = RD::Include.new("include-file-simple-text.odt")
    element.parent = @parent_element
    result = @visitor.apply_to_Include(element)
    result[0].should == <<EOF.chomp.to_sym
<text:p text:style-name='#{@name_prefix}Standard'>これは&lt;&lt;&lt;のサンプルです．</text:p>
EOF
    result[1].should == <<EOF.chomp.to_sym
<text:p text:style-name='#{@name_prefix}Standard'>単純なテキストのincludeサンプルです．</text:p>
EOF
    result[2].should == <<EOF.chomp.to_sym
<text:p text:style-name='#{@name_prefix}Standard'/>
EOF
    result.length.should == 3
    result.class.should == Array
    @visitor.number_of_include_files.should == 1
    @visitor.additional_styles[0].to_s.should == <<EOF.chomp
<style:style style:name='#{@name_prefix}Standard' style:class='text' style:family='paragraph'/>
EOF
    @visitor.additional_styles[1].to_s.should == <<EOF.chomp
<style:style style:name='#{@name_prefix}Text_20_body' style:class='text' style:parent-style-name='#{@name_prefix}Standard' style:display-name='#{@name_prefix}Text body' style:family='paragraph'>
   <style:paragraph-properties fo:margin-bottom='0.212cm' fo:margin-top='0cm'/>
  </style:style>
EOF
    # additional_styles[2..6] test is omitted.
    @visitor.additional_styles.length.should == 7
    @visitor.additional_styles.class == Array
  end

=begin
  it "includes other document" do
    element = RD::Include.new("include-file-simple-styled-text.odt")
    element.parent = @parent_element
    result = @visitor.apply_to_Include(element)
    result[0].should == <<EOF.chomp.to_sym
<text:p text:style-name='Standard'>これは&lt;&lt;&lt;のサンプルです．</text:p>
EOF
    result[1].should == <<EOF.chomp.to_sym
<text:p text:style-name='Standard'>標準: 単純なテキストのincludeサンプルです．</text:p>
EOF
    result[2].should == <<EOF.chomp.to_sym
<text:p text:style-name='Standard'/>
EOF
    result[3].should == <<EOF.chomp.to_sym
<text:h text:outline-level='1' text:style-name='Heading_20_1'>見出し1</text:h>
EOF
    result[4].should == <<EOF.chomp.to_sym
<text:h text:outline-level='2' text:style-name='Heading_20_2'>見出し1.1</text:h>
EOF
    result[5].should == <<EOF.chomp.to_sym
<text:p text:style-name='Text_20_body'>本文</text:p>
EOF
    result[6].should == <<EOF.chomp.to_sym
<text:p text:style-name='Standard'/>
EOF
    result[7].should == <<EOF.chomp.to_sym
<text:p text:style-name='Preformatted_20_Text'>書式設定前テキスト</text:p>
EOF
    result[8].should == <<EOF.chomp.to_sym
<text:p text:style-name='Standard'/>
EOF
    result[9].should == <<EOF.chomp.to_sym
<text:p text:style-name='Standard'>文字用書式スタイルのincludeテスト</text:p>
EOF
    result[10].should == <<EOF.chomp.to_sym
<text:p text:style-name='Standard'><text:span text:style-name='Emphasis'>強調</text:span>標準</text:p>
EOF
    result[11].should == <<EOF.chomp.to_sym
<text:p text:style-name='Standard'><text:span text:style-name='Variable'>変数</text:span>標準</text:p>
EOF
    result[12].should == <<EOF.chomp.to_sym
<text:p text:style-name='Standard'><text:span text:style-name='Teletype'>等幅フォント</text:span>標準</text:p>
EOF
    result[13].should == <<EOF.chomp.to_sym
<text:p text:style-name='Standard'/>
EOF
    result.length.should == 14
    result.class.should == Array
  end
=end

  it "includes other document which containts table:table" do
    element = RD::Include.new("include-file-table.odt")
    element.parent = @parent_element
    result = @visitor.apply_to_Include(element)
    result[0].should == <<EOF.chomp.to_sym
<text:p text:style-name='#{@name_prefix}Standard'>これは&lt;&lt;&lt;のサンプルです．</text:p>
EOF
    result[1].should == <<EOF.chomp.to_sym
<table:table table:name='#{@name_prefix}表1' table:style-name='#{@name_prefix}表1'>
    <table:table-column table:number-columns-repeated='3' table:style-name='#{@name_prefix}表1.A'/>
    <table:table-row>
     <table:table-cell office:value-type='string' table:style-name='#{@name_prefix}表1.A1'>
      <text:p text:style-name='#{@name_prefix}Table_20_Contents'>表つき文書の</text:p>
     </table:table-cell>
     <table:table-cell office:value-type='string' table:style-name='#{@name_prefix}表1.A1'>
      <text:p text:style-name='#{@name_prefix}Table_20_Contents'>埋め込み</text:p>
     </table:table-cell>
     <table:table-cell office:value-type='string' table:style-name='#{@name_prefix}表1.C1'>
      <text:p text:style-name='#{@name_prefix}Table_20_Contents'>サンプル</text:p>
     </table:table-cell>
    </table:table-row>
    <table:table-row>
     <table:table-cell office:value-type='string' table:style-name='#{@name_prefix}表1.A2'>
      <text:p text:style-name='#{@name_prefix}Table_20_Contents'>1</text:p>
     </table:table-cell>
     <table:table-cell office:value-type='string' table:style-name='#{@name_prefix}表1.A2'>
      <text:p text:style-name='#{@name_prefix}Table_20_Contents'>2</text:p>
     </table:table-cell>
     <table:table-cell office:value-type='string' table:style-name='#{@name_prefix}表1.C2'>
      <text:p text:style-name='#{@name_prefix}Table_20_Contents'>3</text:p>
     </table:table-cell>
    </table:table-row>
   </table:table>
EOF
    result[2].should == <<EOF.chomp.to_sym
<text:p text:style-name='#{@name_prefix}Standard'/>
EOF
    result.length.should == 3
    result.class.should == Array
    @visitor.automatic_styles[0].to_s.should == <<EOF.chomp
<style:style style:name='#{@name_prefix}表1' style:family='table'>
   <style:table-properties table:align='margins' style:width='16.999cm'/>
  </style:style>
EOF
    @visitor.automatic_styles[1].to_s.should == <<EOF.chomp
<style:style style:name='#{@name_prefix}表1.A' style:family='table-column'>
   <style:table-column-properties style:column-width='5.666cm' style:rel-column-width='21845*'/>
  </style:style>
EOF
    # automatic_styles[2..5] test is omitted.
    @visitor.automatic_styles.length.should == 6
    @visitor.automatic_styles.class.should == Array
  end

  it "includes other document which containts draw:*" do
    element = RD::Include.new("include-file-shape.odt")
    element.parent = @parent_element
    result = @visitor.apply_to_Include(element)
    result[0].should == <<EOF.chomp.to_sym
<text:p text:style-name='#{@name_prefix}Standard'>これは&lt;&lt;&lt;のサンプルです．</text:p>
EOF
    result[1].should == <<EOF.chomp.to_sym
<text:p text:style-name='#{@name_prefix}Standard'><draw:g text:anchor-type='paragraph' draw:z-index='0' draw:style-name='#{@name_prefix}gr1'><draw:custom-shape svg:x='3.348cm' svg:y='0.088cm' svg:height='3.911cm' draw:style-name='#{@name_prefix}gr2' svg:width='3.887cm'>
      <text:p/>
      <draw:enhanced-geometry draw:glue-points='10800 0 3160 3160 0 10800 3160 18440 10800 21600 18440 18440 21600 10800 18440 3160' draw:type='smiley' draw:enhanced-path='U 10800 10800 10800 10800 0 23592960 Z N U 7305 7515 1165 1165 0 23592960 Z N U 14295 7515 1165 1165 0 23592960 Z N M 4870 ?f1 C 8680 ?f2 12920 ?f2 16730 ?f1 F N' draw:modifiers='17520' draw:text-areas='3200 3200 18400 18400' svg:viewBox='0 0 21600 21600'>
       <draw:equation draw:name='f0' draw:formula='$0 -15510'/>
       <draw:equation draw:name='f1' draw:formula='17520-?f0 '/>
       <draw:equation draw:name='f2' draw:formula='15510+?f0 '/>
       <draw:handle draw:handle-range-y-maximum='17520' draw:handle-range-y-minimum='15510' draw:handle-position='10800 $0'/>
      </draw:enhanced-geometry>
     </draw:custom-shape><draw:custom-shape svg:x='8.225cm' svg:y='0.873cm' draw:text-style-name='P1' svg:height='1.881cm' draw:style-name='#{@name_prefix}gr3' svg:width='3.303cm'>
      <text:p text:style-name='#{@name_prefix}P1'>Yes,</text:p>
      <text:p text:style-name='#{@name_prefix}P1'>This is the sample!</text:p>
      <draw:enhanced-geometry draw:type='round-rectangular-callout' draw:enhanced-path='M 3590 0 X 0 3590 L ?f2 ?f3 0 8970 0 12630 ?f4 ?f5 0 18010 Y 3590 21600 L ?f6 ?f7 8970 21600 12630 21600 ?f8 ?f9 18010 21600 X 21600 18010 L ?f10 ?f11 21600 12630 21600 8970 ?f12 ?f13 21600 3590 Y 18010 0 L ?f14 ?f15 12630 0 8970 0 ?f16 ?f17 Z N' draw:modifiers='-7311.47891083823 20689.0346766635' draw:text-areas='800 800 20800 20800' svg:viewBox='0 0 21600 21600'>
       <draw:equation draw:name='f0' draw:formula='$0 -10800'/>
       <draw:equation draw:name='f1' draw:formula='$1 -10800'/>
       <draw:equation draw:name='f2' draw:formula='if(?f18 ,$0 ,0)'/>
       <draw:equation draw:name='f3' draw:formula='if(?f18 ,$1 ,6280)'/>
       <draw:equation draw:name='f4' draw:formula='if(?f23 ,$0 ,0)'/>
       <draw:equation draw:name='f5' draw:formula='if(?f23 ,$1 ,15320)'/>
       <draw:equation draw:name='f6' draw:formula='if(?f26 ,$0 ,6280)'/>
       <draw:equation draw:name='f7' draw:formula='if(?f26 ,$1 ,21600)'/>
       <draw:equation draw:name='f8' draw:formula='if(?f29 ,$0 ,15320)'/>
       <draw:equation draw:name='f9' draw:formula='if(?f29 ,$1 ,21600)'/>
       <draw:equation draw:name='f10' draw:formula='if(?f32 ,$0 ,21600)'/>
       <draw:equation draw:name='f11' draw:formula='if(?f32 ,$1 ,15320)'/>
       <draw:equation draw:name='f12' draw:formula='if(?f34 ,$0 ,21600)'/>
       <draw:equation draw:name='f13' draw:formula='if(?f34 ,$1 ,6280)'/>
       <draw:equation draw:name='f14' draw:formula='if(?f36 ,$0 ,15320)'/>
       <draw:equation draw:name='f15' draw:formula='if(?f36 ,$1 ,0)'/>
       <draw:equation draw:name='f16' draw:formula='if(?f38 ,$0 ,6280)'/>
       <draw:equation draw:name='f17' draw:formula='if(?f38 ,$1 ,0)'/>
       <draw:equation draw:name='f18' draw:formula='if($0 ,-1,?f19 )'/>
       <draw:equation draw:name='f19' draw:formula='if(?f1 ,-1,?f22 )'/>
       <draw:equation draw:name='f20' draw:formula='abs(?f0 )'/>
       <draw:equation draw:name='f21' draw:formula='abs(?f1 )'/>
       <draw:equation draw:name='f22' draw:formula='?f20 -?f21 '/>
       <draw:equation draw:name='f23' draw:formula='if($0 ,-1,?f24 )'/>
       <draw:equation draw:name='f24' draw:formula='if(?f1 ,?f22 ,-1)'/>
       <draw:equation draw:name='f25' draw:formula='$1 -21600'/>
       <draw:equation draw:name='f26' draw:formula='if(?f25 ,?f27 ,-1)'/>
       <draw:equation draw:name='f27' draw:formula='if(?f0 ,-1,?f28 )'/>
       <draw:equation draw:name='f28' draw:formula='?f21 -?f20 '/>
       <draw:equation draw:name='f29' draw:formula='if(?f25 ,?f30 ,-1)'/>
       <draw:equation draw:name='f30' draw:formula='if(?f0 ,?f28 ,-1)'/>
       <draw:equation draw:name='f31' draw:formula='$0 -21600'/>
       <draw:equation draw:name='f32' draw:formula='if(?f31 ,?f33 ,-1)'/>
       <draw:equation draw:name='f33' draw:formula='if(?f1 ,?f22 ,-1)'/>
       <draw:equation draw:name='f34' draw:formula='if(?f31 ,?f35 ,-1)'/>
       <draw:equation draw:name='f35' draw:formula='if(?f1 ,-1,?f22 )'/>
       <draw:equation draw:name='f36' draw:formula='if($1 ,-1,?f37 )'/>
       <draw:equation draw:name='f37' draw:formula='if(?f0 ,?f28 ,-1)'/>
       <draw:equation draw:name='f38' draw:formula='if($1 ,-1,?f39 )'/>
       <draw:equation draw:name='f39' draw:formula='if(?f0 ,-1,?f28 )'/>
       <draw:equation draw:name='f40' draw:formula='$0 '/>
       <draw:equation draw:name='f41' draw:formula='$1 '/>
       <draw:handle draw:handle-position='$0 $1'/>
      </draw:enhanced-geometry>
     </draw:custom-shape>
    </draw:g>シェイプ付きのOpen Documentファイルです．</text:p>
EOF
    result[2].should == <<EOF.chomp.to_sym
<text:p text:style-name='#{@name_prefix}Standard'/>
EOF
    result.length.should == 3
    result.class.should == Array
    @visitor.automatic_styles[0].to_s.should == <<EOF.chomp
<style:style style:name='#{@name_prefix}P1' style:family='paragraph'>
   <style:paragraph-properties fo:text-align='center'/>
  </style:style>
EOF
    @visitor.automatic_styles[1].to_s.should == <<EOF.chomp
<style:style style:name='#{@name_prefix}gr1' style:family='graphic'>
   <style:graphic-properties style:flow-with-text='false' style:horizontal-pos='from-left' style:wrap='none' style:vertical-rel='paragraph' draw:wrap-influence-on-position='once-concurrent' style:horizontal-rel='paragraph' style:run-through='foreground' style:vertical-pos='from-top'/>
  </style:style>
EOF
    @visitor.automatic_styles[2].to_s.should == <<EOF.chomp
<style:style style:name='#{@name_prefix}gr2' style:family='graphic'>
   <style:graphic-properties draw:textarea-vertical-align='middle' draw:auto-grow-height='false' style:run-through='foreground' draw:textarea-horizontal-align='justify'/>
  </style:style>
EOF
    # automatic_styles[3] test is omitted.
    @visitor.automatic_styles.length.should == 4
    @visitor.automatic_styles.class.should == Array
  end
end
