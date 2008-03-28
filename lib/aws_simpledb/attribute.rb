module AWSSimpleDB
    class Attribute
      attr_accessor :name, :value, :index
      def initial(name,value)
        @name = name
        @value = value
      end
    end
end