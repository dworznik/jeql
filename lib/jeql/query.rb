module Jeql
  class Query
    attr_reader :query_name

    def initialize(query_name, source_dir, endpoint_config, context)
      @context = context
      @query_name = query_name
      @query_file = File.read File.expand_path "./_graphql/#{query_name}.json", source_dir
      @endpoint_config = endpoint_config
    end

    def response
      @memoized_responses ||= {}
      @memoized_responses[@query_name] ||= execute
    end

    private

    def execute
      query_tmpl = Liquid::Template.parse(@query_file)
      query_content = query_tmpl.render(@context)
      conn = Faraday.new(url: @endpoint_config["url"], request: timeout_settings)
      response = conn.post do |req|
        req.headers = (@endpoint_config["header"] || {}).merge('Content-Type' => 'application/json')
        req.body = query_content
      end
    end

    def timeout_settings
      {open_timeout: 2, timeout: 2}
    end
  end
end
