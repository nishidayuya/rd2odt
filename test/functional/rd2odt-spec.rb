# -*- coding: utf-8 -*-

require File.join(File.dirname(__FILE__), "..", "test-helper")

def create_rd_tree(filename)
  path = File.join($top_srcdir, "doc", "sample", filename)
  tree = RD::RDTree.new(File.read(path), [], nil)
  tree.parse
  return tree
end

def check_document_content(result)
  result.class.should == Array
  result[0].should == :office__document_content
  result[1].should == {
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
    :xmlns__number => "urn:oasis:names:tc:opendocument:xmlns:datastyle:1.0",
    :xmlns__svg => "urn:oasis:names:tc:opendocument:xmlns:svg-compatible:1.0",
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
  }
  result[2].should == [:office__scripts]
  result[3].should == [:office__font_face_decls,
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
                      ] # :office__font_face_decls
  result[4].should == [:office__automatic_styles]
  body_result = result[5]
  body_result.class.should == Array
  body_result[0].should == :office__body
  body_result[1].class.should == Array
  body_result[1][0].should == :office__text
  body_result[1][1].should == [:text__sequence_decls,
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
                              ] # :text__sequence_decls
  return yield(body_result[1][2 .. -1])
end

describe RD2ODT::RD2ODTVisitor, "" do
  before do
    @visitor = RD2ODT::RD2ODTVisitor.new
  end

  it "process multi-paragraph.rd" do
    result = @visitor.visit(create_rd_tree("multi-paragraph.rd"))
    check_document_content(result) do |office_text|
      office_text[0].should == [:text__p,
                                {:text__style_name => "Text_20_body"},
                                "段落1段落1"
                               ]
      office_text[1].should == [:text__p,
                                {:text__style_name => "Text_20_body"},
                                "段落2段落2"
                               ]
      office_text[2].should == [:text__p,
                                {:text__style_name => "Text_20_body"},
                                "段落3段落3"
                               ]
    end
  end

  it "process headline.rd" do
    result = @visitor.visit(create_rd_tree("headline.rd"))
    check_document_content(result) do |office_text|
      office_text[0].should == [:text__list,
                                {:text__style_name => "Numbering_20_2"},
                                [:text__list_item,
                                 [:text__p,
                                  {:text__style_name => "Heading_20_1"},
                                  "レベル1: 見出し1",
                                 ],
                                ],
                               ]
      office_text[1].should == [:text__p,
                                {:text__style_name => "Text_20_body"},
                                "本文1",
                               ]
      office_text[2].should == [:text__list,
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
                                    "レベル2: 見出し1.1",
                                   ],
                                  ],
                                 ],
                                ],
                               ]
      office_text[3].should == [:text__p,
                                {:text__style_name => "Text_20_body"},
                                "本文1.1",
                               ]
      office_text[4].should == [:text__list,
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
                                      "レベル3: 見出し1.1.1",
                                     ],
                                    ],
                                   ],
                                  ],
                                 ],
                                ],
                               ]
      office_text[5].should == [:text__p,
                                {:text__style_name => "Text_20_body"},
                                "本文1.1.1",
                               ]
      office_text[6].should == [:text__list,
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
                                     [:text__list,
                                      {:text__continue_numbering => "true"},
                                      [:text__list_item,
                                       [:text__p,
                                        {:text__style_name => "Heading_20_4"},
                                        "レベル4: 見出し1.1.1.1",
                                       ],
                                      ],
                                     ],
                                    ],
                                   ],
                                  ],
                                 ],
                                ],
                               ]
      office_text[7].should == [:text__p,
                                {:text__style_name => "Text_20_body"},
                                "本文1.1.1.1",
                               ]
      office_text[8].should ==
        [:text__list,
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
              [:text__list,
               {:text__continue_numbering => "true"},
               [:text__list_item,
                [:text__list,
                 {:text__continue_numbering => "true"},
                 [:text__list_item,
                  [:text__p,
                   {:text__style_name => "Heading_20_5"},
                   "レベル5: 見出し1.1.1.1.1",
                  ],
                 ],
                ],
               ],
              ],
             ],
            ],
           ],
          ],
         ],
        ]
      office_text[9].should == [:text__p,
                                {:text__style_name => "Text_20_body"},
                                "本文1.1.1.1.1",
                               ]
      office_text[10].should ==
        [:text__list,
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
              [:text__list,
               {:text__continue_numbering => "true"},
               [:text__list_item,
                [:text__list,
                 {:text__continue_numbering => "true"},
                 [:text__list_item,
                  [:text__list,
                   {:text__continue_numbering => "true"},
                   [:text__list_item,
                    [:text__p,
                     {:text__style_name => "Heading_20_6"},
                     "レベル6: 見出し1.1.1.1.1.1",
                    ],
                   ],
                  ],
                 ],
                ],
               ],
              ],
             ],
            ],
           ],
          ],
         ],
        ]
      office_text[11].should == [:text__p,
                                 {:text__style_name => "Text_20_body"},
                                 "本文1.1.1.1.1.1",
                                ]
      office_text[12].should ==
        [:text__list,
         {
           :text__style_name => "Numbering_20_2",
           :text__continue_numbering => "true",
         },
         [:text__list_item,
          [:text__p,
           {:text__style_name => "Heading_20_1"},
           "見出し2",
          ],
         ],
        ]
      office_text[13].should == [:text__p,
                                 {:text__style_name => "Text_20_body"},
                                 "本文2",
                                ]
      office_text[14].should ==
        [:text__list,
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
             "見出し2.1",
            ],
           ],
          ],
         ],
        ]
      office_text[15].should == [:text__p,
                                 {:text__style_name => "Text_20_body"},
                                 "本文2.1",
                                ]
      office_text[16].should ==
        [:text__list,
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
             "見出し2.2",
            ],
           ],
          ],
         ],
        ]
      office_text[17].should == [:text__p,
                                 {:text__style_name => "Text_20_body"},
                                 "本文2.2",
                                ]
      office_text[18].should ==
        [:text__list,
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
               "見出し2.2.1",
              ],
             ],
            ],
           ],
          ],
         ],
        ]
      office_text[19].should == [:text__p,
                                 {:text__style_name => "Text_20_body"},
                                 "本文2.2.1",
                                ]
      office_text[20].should ==
        [:text__list,
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
             "見出し2.3",
            ],
           ],
          ],
         ],
        ]
      office_text[21].should == [:text__p,
                                 {:text__style_name => "Text_20_body"},
                                 "本文2.3",
                                ]
      office_text[22].should ==
        [:text__list,
         {
           :text__style_name => "Numbering_20_2",
           :text__continue_numbering => "true",
         },
         [:text__list_item,
          [:text__p,
           {:text__style_name => "Heading_20_1"},
           "見出し3",
          ],
         ],
        ]
      office_text[23].should == [:text__p,
                                 {:text__style_name => "Text_20_body"},
                                 "本文3",
                                ]
      office_text[24].should ==
        [:text__list,
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
               "見出し3.1.1",
              ],
             ],
            ],
           ],
          ],
         ],
        ]
      office_text[25].should == [:text__p,
                                 {:text__style_name => "Text_20_body"},
                                 "本文3.1.1",
                                ]
      office_text[26].should ==
        [:text__list,
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
             "見出し3.2",
            ],
           ],
          ],
         ],
        ]
      office_text[27].should == [:text__p,
                                 {:text__style_name => "Text_20_body"},
                                 "本文3.2",
                                ]
      office_text.length.should == 28
    end
  end
end
