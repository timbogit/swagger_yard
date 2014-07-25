module SwaggerYard
  class ResourceListing
    attr_reader :api_declarations, :resource_to_file_path
    attr_accessor :authorizations

    def initialize(controller_path, model_path)
      @model_path = model_path
      @controller_path = controller_path

      @resource_to_file_path = {}
      @authorizations = []
    end

    def models
      @models ||= parse_models
    end

    def controllers
      @controllers ||= parse_controllers
    end

    def declaration_for(resource_name)
      controllers[resource_name]
    end

    def to_h
      { 
        "apiVersion"      => SwaggerYard.config.api_version,
        "swaggerVersion"  => SwaggerYard.config.swagger_version,
        "basePath"        => SwaggerYard.config.swagger_spec_base_path,
        "apis"            => list_api_declarations,
        "authorizations"  => authorizations_hash
      }
    end

  private
    def list_api_declarations
      controllers.values.sort_by(&:resource_path).map(&:listing_hash)
    end

    def parse_models
      return [] unless @model_path

      Dir[@model_path].map do |file_path|
        Model.from_yard_objects(SwaggerYard.yard_objects_from_file(file_path))
      end.compact.select(&:valid?)
    end

    def parse_controllers
      return {} unless @controller_path

      Hash[Dir[@controller_path].map do |file_path|
        declaration = create_api_declaration(file_path)

        [declaration.resource_name, declaration] if declaration.valid?
      end.compact]
    end

    def create_api_declaration(file_path)
      yard_objects = SwaggerYard.yard_objects_from_file(file_path)

      ApiDeclaration.new(self).add_yard_objects(yard_objects)
    end

    def authorizations_hash
      p authorizations
      Hash[
        authorizations.map(&:name).zip(authorizations.map(&:to_h)) # ugh
      ]
    end
  end
end
