class Jeql::GraphqlBlock < Liquid::Block
  GraphQlError = Class.new(Jekyll::Errors::FatalException)
  LITERALS_SYNTAX = /(\w+):\s*['"](\w+)['"],?/
  VARS_SYNTAX = /(\w+):\s*(\w+)\s*,?/

  def initialize(tag_name, text, tokens)
    super
    @literals = Hash[text.scan(LITERALS_SYNTAX)]
    @vars = Hash[text.scan(VARS_SYNTAX)]
    @text = text
  end

  def get_value(context, name)
    if @literals.has_key?(name)
      return @literals[name]
    elsif @vars.has_key?(name)
      return context[name]
    end
  end

  def render(context)
    endpoint_config = context.registers[:site].config["jeql"][self.get_value(context, "endpoint")]
    query = Jeql::Query.new(self.get_value(context, "query"), context.registers[:site].config["source"], endpoint_config, context)
    var_name = self.get_value(context, "endpoint") + "_" + (self.get_value(context, "var") || "data")
    print var_name
    if query.response.success?
      context[var_name] = JSON.parse(query.response.body)['data']
      super
    else
      raise GraphQlError, "The query #{query.query_name} failed"
    end
  end
end

Liquid::Template.register_tag('graphql', Jeql::GraphqlBlock)
