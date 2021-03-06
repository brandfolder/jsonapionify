require 'erb'
require 'redcarpet'
require 'active_support/core_ext/string/inflections'
require 'active_support/core_ext/array'
require 'redcarpet/render_strip'

module JSONAPIonify
  class Documentation
    using JSONAPIonify::IndentedString
    STRIPPER = Redcarpet::Markdown.new(Redcarpet::Render::StripDown)
    RENDERER = Redcarpet::Markdown.new(
      Redcarpet::Render::HTML,
      autolink:                     true,
      tables:                       true,
      fenced_code_blocks:           true,
      strikethrough:                true,
      disable_indented_code_blocks: true,
      no_intra_emphasis:            true,
      space_after_headers:          true,
      underline:                    true,
      highlight:                    true,
      quote:                        true
    )

    def self.render_markdown(string)
      RENDERER.render(string.deindent)
    end

    def self.onelinify_markdown(string)
      strip_markdown(string).gsub(/[\r\n\t]/, ' ').strip
    end

    def self.strip_markdown(string)
      STRIPPER.render(string.deindent)
    end

    attr_reader :api

    def initialize(api, template: nil)
      template ||= File.join(__dir__, 'documentation/template.erb')
      @api     = api
      @erb     = ERB.new File.read(template)
    end

    def result
      @erb.result(binding)
    end

  end
end
