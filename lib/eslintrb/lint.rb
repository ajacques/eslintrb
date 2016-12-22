# encoding: UTF-8

require "execjs"
require "multi_json"

module Eslintrb

  class Lint
    Error = ExecJS::Error

    # Default options for compilation
    DEFAULTS = {
      rules: {
        'no-bitwise' => 2,
        'curly' => 2,
        'eqeqeq' => 2,
        'guard-for-in' => 2,
        'no-use-before-define' => 2,
        'no-caller' => 2,
        'no-new-func' => 2,
        'no-plusplus' => 2,
        'no-undef' => 2,
        'strict' => 2
      },
      env: {
        'browser' => true
      }
    }

    SourcePath = File.expand_path("../../js/eslint.js", __FILE__)

    def initialize(options = nil, globals = nil)

      if options == :defaults then
        @options = DEFAULTS.dup
      elsif options == :eslintrc then
        @options = load_eslintrc_config
      elsif options.instance_of? Hash then
        @options = options.dup
        # @options = DEFAULTS.merge(options)
      elsif options.nil?
        @options = nil
      else
        raise 'Unsupported option for Eslintrb: ' + options.to_s
      end

      @globals = globals

      @context = ExecJS.compile("var window = {}; \n" + File.open(SourcePath, "r:UTF-8").read)
    end

    def lint(source)
      source = source.respond_to?(:read) ? source.read : source.to_s

      js = ["var errors;"]
      if @options.nil? and @globals.nil? then
        js << "errors = window.eslint.verify(#{MultiJson.dump(source)}, {});"
      elsif @globals.nil? then
        js << "errors = window.eslint.verify(#{MultiJson.dump(source)}, #{MultiJson.dump(@options)});"
      else
        globals_hash = Hash[*@globals.product([false]).flatten]
        @options = @options.merge({globals: globals_hash})
        js << "errors = window.eslint.verify(#{MultiJson.dump(source)}, #{MultiJson.dump(@options)});"
      end
      js << "return errors;"

      @context.exec js.join("\n")
    end

    private

    def load_eslintrc_config
      if File.exists?('./.eslinrc')
        MultiJson.load(File.read('./.eslintrc'))
      elsif File.exist?('./.eslintrc.yml')
        YAML.load_file('./.eslintrc.yml')
      else
        raise 'Did not find either `.eslintrc` or `.eslintrc.yml` in the current working directory.'
      end
    end
  end
end
