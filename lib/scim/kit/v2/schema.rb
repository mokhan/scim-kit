# frozen_string_literal: true

module Scim
  module Kit
    module V2
      # Represents a SCIM Schema
      class Schema
        include Templatable
        ERROR = 'urn:ietf:params:scim:api:messages:2.0:Error'
        GROUP = 'urn:ietf:params:scim:schemas:core:2.0:Group'
        RESOURCE_TYPE = 'urn:ietf:params:scim:schemas:core:2.0:ResourceType'
        SERVICE_PROVIDER_CONFIGURATION = 'urn:ietf:params:scim:schemas:core:2.0:ServiceProviderConfig'
        USER = 'urn:ietf:params:scim:schemas:core:2.0:User'

        attr_reader :id, :name, :location, :attributes
        attr_accessor :description

        def initialize(id:, name:, location:)
          @id = id
          @name = name
          @location = location
          @attributes = []
        end

        def add_attribute(name:, type: :string)
          attribute = AttributeType.new(name: name, type: type)
          yield attribute if block_given?
          @attributes << attribute
        end

        def self.build(*args)
          item = new(*args)
          yield item
          item
        end
      end
    end
  end
end
