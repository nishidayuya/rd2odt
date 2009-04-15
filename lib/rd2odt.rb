# -*- coding: utf-8 -*-

require "pp"
require "optparse"
require "find"
require "tmpdir"
require "cgi"
require "rexml/document"
begin
  require "rd/rdvisitor"
  require "rd/rdfmt"
  require "zip/zip"
rescue LoadError
  require "rubygems"
  require "rd/rdvisitor"
  require "rd/rdfmt"
  require "zip/zip"
end

module RD2ODT
  @@options = {
    :backtrace => false,
    :template => nil,
  }
  OPTION_PARSER = OptionParser.new
  OPTION_PARSER.banner = "Usage: #{OPTION_PARSER.program_name} [options] input-file-path.rd [output-file-path.odt]"
  OPTION_PARSER.on("--backtrace", "print backtrace") do
    @@options[:backtrace] = true
  end
  OPTION_PARSER.on("--template=TEMPLATE", "specify template filename") do |arg|
    @@options[:template] = arg
  end

  def options
    return @@options
  end
  module_function :options

  def parse_option(argv)
    begin
      OPTION_PARSER.parse!(argv)
    rescue OptionParser::ParseError => e
      raise ProgramOptionParseError, e
    end

    @@input_path = argv.shift
    if @@input_path.nil?
      raise ProgramOptionError, "no input file path."
    end

    @@output_path =
      argv.shift ||
      (@@input_path == "-" ? "output.odt" : @@input_path + ".odt")

    if options[:template].nil?
      options[:template] = @@input_path + ".ott"
    end
    @@input_path
  end
  module_function :parse_option

  def main(argv)
    parse_option(argv)

    include_paths = [
                     File.dirname(@@input_path),
                     File.dirname(@@output_path),
                    ]

    puts("input_path: " + @@input_path.inspect) if $DEBUG
    puts("output_path: " + @@output_path.inspect) if $DEBUG
    puts("options: " + options.inspect) if $DEBUG
    puts("include_paths: " + include_paths.inspect) if $DEBUG

    input_lines = treat_input(File.readlines(@@input_path))
    tree = RD::RDTree.new(input_lines, include_paths, nil)
    tree.parse
    visitor = RD2ODTVisitor.new
    doc = visitor.visit(tree)
    create_odt(visitor, doc, @@output_path, options[:template])
  rescue Error => e
    e.process
  end
  module_function :main

  def self.treat_input(lines)
    result = lines.dup

    if lines.grep(/^=begin\b/).empty? &&
        lines.grep(/^=end\b/).empty?
      result.unshift("=begin\n")

      if !(/\n\z/ === result[-1])
        result[-1] = result[-1] + "\n"
      end
      result.push("=end\n")
    end

    return result
  end

  def self.create_odt(visitor, doc, output_path, template_path)
    current_path = Dir.pwd
    output_absolute_path = File.expand_path(output_path)
    template_absolute_path = File.expand_path(template_path)
    Dir.mktmpdir do |tmpdir|
      Dir.chdir(tmpdir) do
        unzip(template_absolute_path)
        open("styles.xml", "r+") do |f|
          operate_styles_xml(f, visitor.additional_styles)
        end
        open("content.xml", "w") do |f|
          f.puts('<?xml version="1.0" encoding="UTF-8"?>')
          f.puts
          f.puts(ah_to_xml(doc))
        end
        # todo: test
        # todo: extract only inner_object.href for more optimizing.
        visitor.inner_objects.each do |inner_object|
          Dir.mktmpdir do |dir|
            Dir.chdir(dir) do
              unzip(File.join(current_path, inner_object.path))
              from = inner_object.href
              to = File.join(tmpdir, inner_object.fixed_href)
              FileUtils.mkdir_p(File.dirname(to))
              FileUtils.mv(from, to)
            end
          end
        end
        zip(output_absolute_path)
      end
    end
  end

  # very lazy formatter
  def self.ah_to_xml(o)
    return __send__("ah_to_xml_by_" + o.class.name.downcase, o)
  end

  def self.ah_to_xml_by_array(ary)
    if ary.first.is_a?(Array) ||
      ary.first.is_a?(Symbol) && /<.*>/ === ary.first.to_s
      # This case is:
      #   [[:tag], [:tag]]
      #       |
      #       v
      #   <tag></tag>
      #   <tag></tag>
      return ary.map { |item|
        ah_to_xml(item)
      }.join("\n")
    end

    ary = ary.dup
    result = "<"

    tag_name = ah_to_xml(ary.shift)
    result << tag_name

    if Hash === ary.first
      h = ary.shift
      result << ah_to_xml_by_hash(h)
    end

    if ary.empty?
      result << " />"
      return result
    end

    result << ">"

    ary.each do |item|
      case item
      when Array
        result << "\n"
        result << ah_to_xml_by_array(item).gsub(/^/, " ")
        result << "\n"
      else
        result << ah_to_xml(item)
      end
    end

    result << "</" + tag_name + ">"

    return result
  end

  def self.ah_to_xml_by_symbol(symbol)
    return symbol.to_s.gsub("__", ":").gsub("_", "-")
  end

  def self.ah_to_xml_by_hash(h)
    return h.keys.sort_by { |item|
      item.to_s
    }.map { |key|
      converted_key = ah_to_xml_by_symbol(key)

      value = h[key]
      converted_value = ah_to_xml_by_string(value)

      " " + converted_key + "=" + '"' + converted_value + '"'
    }.join
  end

  def self.ah_to_xml_by_string(s)
    return CGI.escapeHTML(s.to_s)
  end

  def self.operate_styles_xml(io, additional_styles)
    parser = REXML::Document.new(io.read)
    office_styles = parser.elements["/office:document-styles/office:styles"]
    additional_styles.each do |element|
      office_styles.add_element(element)
    end

    io.rewind
    io.truncate(0)
    io.write(parser.to_s)
  end

  # create zip file by current directory.
  def self.zip(output_path)
    # if !system("zip", "-9qr", output_path, ".")
    #   raise "zip failure: #{output_path.inspect}"
    # end
    FileUtils.rm_f(output_path)
    Zip::ZipFile.open(output_path, Zip::ZipFile::CREATE) do |zip_file|
      Find.find(".") do |path_orig|
        path = path_orig.sub(/\A\.\//, "")  # remove "./"
        if File.file?(path)
          zip_file.get_output_stream(path) do |f|
            f.write(File.read(path))
          end
        elsif File.directory?(path)
          zip_file.mkdir(path)
        end
      end
    end
  end

  # unzip to current directory.
  def self.unzip(input_path)
    # if !system("unzip", "-q", input_path)
    #   raise "unzip failure: #{input_path.inspect}"
    # end
    Zip::ZipFile.foreach(input_path) do |zip_entry|
      path = zip_entry.name
      if zip_entry.directory?
        FileUtils.mkdir_p(path)
      elsif zip_entry.file?
        FileUtils.mkdir_p(File.dirname(path))
        zip_entry.get_input_stream do |input|
          open(path, "w") do |output|
            output.write(input.read)
          end
        end
      end
    end
  end

  class RD2ODTVisitor < RD::RDVisitor
    attr_accessor :continue_numbering_headline

    # for content.xml#/office:document-content/office:automatic-styles
    attr_accessor :automatic_styles

    # for styles.xml#/office:document-styles/office:styles
    attr_accessor :additional_styles

    attr_accessor :number_of_include_files

    # included OLE objects
    attr_accessor :inner_objects

    def initialize(*args)
      super

      self.number_of_include_files = 0
      self.additional_styles = []
      self.automatic_styles = []
      self.inner_objects = []
    end

    def apply_to_DocumentElement(element, sub_content)
      result =
        [:office__document_content,
         {
           :xmlns__office =>
           "urn:oasis:names:tc:opendocument:xmlns:office:1.0",
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
           :xmlns__script =>
           "urn:oasis:names:tc:opendocument:xmlns:script:1.0",
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
          *self.automatic_styles.map { |element|
            element.to_s.to_sym
          }],
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
           *sub_content
          ], # :office__text
         ], # :office__body
        ] # :office__document_content
      return result
    end

    def apply_to_TextBlock(element, sub_contents)
      return [:text__p,
              {:text__style_name => "Text_20_body"},
              *sub_contents
             ]
    end

    def apply_to_StringElement(element)
      return element.content.gsub(/[\r\n]+/m, "")
    end

    def create_headline_result(title, original_level, current_level)
      if current_level.zero?
        return [:text__p,
                {:text__style_name => "Heading_20_#{original_level}"},
                *title
               ]
      else
        return [:text__list,
                {:text__continue_numbering => "true"},
                [:text__list_item,
                 create_headline_result(title, original_level,
                                        current_level - 1)
                ],
               ]
      end
    end
    private :create_headline_result

    def apply_to_Headline(element, title)
      level = element.level
      result = create_headline_result(title, level, level)
      result[1][:text__style_name] = "Numbering_20_2"
      if level == 1 && !continue_numbering_headline
        result[1].delete(:text__continue_numbering)
      end
      self.continue_numbering_headline = true
      return result
    end

    def apply_to_EnumList(element, items)
      return apply_to_list(items,
                           :text__style_name => "Numbering_20_1",
                           :text__continue_numbering => "false")
    end

    def apply_to_ItemList(element, items)
      return apply_to_list(items, :text__style_name => "List_20_1")
    end

    def apply_to_list(items, attributes)
      return [:text__list, attributes, *items]
    end
    private :apply_to_list

    def apply_to_EnumListItem(element, sub_contents)
      return apply_to_list_item(sub_contents)
    end

    def apply_to_ItemListItem(element, sub_contents)
      return apply_to_list_item(sub_contents)
    end

    def apply_to_list_item(sub_contents)
      return [:text__list_item, *sub_contents]
    end
    private :apply_to_list_item

    def apply_to_Verbatim(element)
      lines = element.content.map { |line|
        escape_text(line.chomp)
      }
      return [:text__p,
              {:text__style_name=>"Preformatted_20_Text"},
              lines.join("<text:line-break />").to_sym,
             ]
    end

    def escape_text(text)
      return CGI.escapeHTML(text).gsub(/ {2,}/) {
        num_space_chars = Regexp.last_match.to_s.length
        %Q'<text:s text:c="#{num_space_chars}" />'
      }.gsub("\t", "<text:tab />")
    end
    private :escape_text

    DO_NOT_INCLUDE_TAG_NAMES = ["office:forms", "text:sequence-decls"]

    def apply_to_Include(element)
      self.number_of_include_files += 1
      name_prefix = create_name_prefix
      path = search_file(element.tree.include_paths, element.filename)

      append_children = []
      content_xml = read_file_in_zip(path, "content.xml")
      parser = REXML::Document.new(content_xml)
      office_text =
        parser.elements["/office:document-content/office:body/office:text"]
      apply_prefix_to_xlink_href(path, office_text, name_prefix) # todo: test
      [
       "text:style-name",
       "table:style-name",
       "table:name",
       "draw:style-name",
      ].each do |attribute_key|
        apply_prefix_to_all_of_style_name(office_text, attribute_key,
                                          name_prefix)
      end
      office_text.each_element do |child|
        # may use XPath.
        next if DO_NOT_INCLUDE_TAG_NAMES.include?(child.expanded_name)
        append_children << child.to_s.to_sym
      end

      office_automatic_styles =
        parser.elements["/office:document-content/office:automatic-styles"]
      apply_prefix_to_all_of_style_name(office_automatic_styles,
                                        "style:name", name_prefix)
      office_automatic_styles.each_element do |child|
        self.automatic_styles << child.deep_clone
      end

      styles_xml = read_file_in_zip(path, "styles.xml")
      parser = REXML::Document.new(styles_xml)
      office_styles = parser.elements["/office:document-styles/office:styles"]
      [
       "style:name",
       "style:parent-style-name",
       "style:display-name",
      ].each do |attribute_key|
        apply_prefix_to_all_of_style_name(office_styles, attribute_key,
                                          name_prefix)
      end
      office_styles.elements.each("style:style") do |element|
        self.additional_styles << element
      end

      return append_children
    end

    def search_file(include_paths, filename)
      include_paths.each do |d|
        path = File.join(d, filename)
        return path if File.exist?(path)
      end
      raise "file not found: #{filename.inspect}, #{include_paths.inspect}"
    end
    private :search_file

    def read_file_in_zip(zip_path, path_in_zip)
      # return `unzip -c #{zip_path} #{path_in_zip}`
      Zip::ZipFile.open(zip_path) do |zip_file|
        return zip_file.read(path_in_zip)
      end
    end
    private :read_file_in_zip

    def create_name_prefix
      t = Time.now
      return sprintf("rd2odt:%d:%06d:%d:",
                     t.tv_sec, t.tv_usec, number_of_include_files)
    end
    private :create_name_prefix

    def apply_prefix_to_all_of_style_name(start_element, attribute_key,
                                          name_prefix)
      start_element.elements.each("//*[@#{attribute_key}]") do |element|
        element.attributes[attribute_key] =
          name_prefix + element.attributes[attribute_key]
      end
    end
    private :apply_prefix_to_all_of_style_name

    # todo: test
    def apply_prefix_to_xlink_href(path, office_text, name_prefix)
      # <draw:object> and <draw:image>
      office_text.elements.each("//*[@xlink:href]") do |element|
        href = element.attributes["xlink:href"]
        fixed_href = File.join(File.dirname(href),
                               name_prefix + File.basename(href))
        element.attributes["xlink:href"] = fixed_href
        self.inner_objects << InnerObject.new(path, href, fixed_href)
      end
    end
    private :apply_prefix_to_xlink_href
  end

  InnerObject = Struct.new(:path, :href, :fixed_href)

  class Error < StandardError
    def process
      if RD2ODT.options[:backtrace]
        STDERR.puts("backtrace:")
        STDERR.puts(backtrace.map { |l|
                      "  " + l
                    })
      end
      STDERR.puts(message)
      exit(1)
    end
  end

  class ProgramOptionError < Error
    ADDITIONAL_MESSAGE = [RD2ODT::OPTION_PARSER.banner,
                          "use #{RD2ODT::OPTION_PARSER.program_name} --help for more help."]

    def message
      return [super, "", *ADDITIONAL_MESSAGE]
    end
  end

  class ProgramOptionParseError < ProgramOptionError
    def initialize(e)
      @e = e
    end

    def message
      return [@e.message, "", *ADDITIONAL_MESSAGE]
    end

    def backtrace
      return @e.backtrace
    end
  end
end
