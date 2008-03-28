module AWSSimpleDB
  # Item is a class that represents the attributes
  # associated with a domain by the item name
  ATTR='Attribute'
  class Item < BaseRequest
    attr_accessor :name, :attributes, :domain
    def initialize
      super
      @attributes = {}
    end
    def add_attribute(name,value)
      @attributes[name] = value
    end
    
    def remove_attribute(name)
      @attributes.delete(name)
    end
    
    def replace_attribute(name,value)
      @attributes[name]=value
    end
    
    def <<(hash)
      @attributes.update(hash)
      create_instance_variables(hash)
    end
    
    
    
    
    def create
      logger.info("create: entry")
      action = ACTION.gsub('VALUE','PutAttributes')
      name = "ItemName=#{@name}"
      domain = "DomainName=#{@domain}"
      params = [action,build_attribute_params,name,domain]
      params.flatten!
      #build request
      response = send_request(params)
      value = self.class.translate(response,'PutAttributesResponse')
      raise InvalidRequest.new("Unable to create domain") if value.nil?
      logger.info("create: exit #{value}")
      @name
    end
    
    
    def list
      logger.info("list: entry")
      action = ACTION.gsub('VALUE','GetAttributes')
      attributes = build_attribute_params
      name = "ItemName=#{@name}"
      domain = "DomainName=#{@domain}"
      params = [action,name,domain]
      #build request
      response = send_request(params)
      value = translate_attributes(response)
      @attributes = value
      raise InvalidRequest.new("Unable to list attributes") if value.nil?
      logger.info("list: exit")
      value
    end
    
    
    def delete
      logger.info("delete: entry")
      action = ACTION.gsub('VALUE','DeleteAttributes')
      attributes = build_attribute_params
      name = "ItemName=#{@name}"
      domain = "DomainName=#{@domain}"
      params = [action,name,domain]
      #build request
      response = send_request(params)
      value = self.class.translate(response,'DeleteAttributesResponse')
      raise InvalidRequest.new("Unable to delete attributes") if value.nil?
      logger.info("delete: exit #{value}")
      value
    end
    
    
    # Find
    # ex: "['Color'='Blue']"
    def find_by_query(query)
      logger.info("find_by_query: entry #{query}")
      action = ACTION.gsub('VALUE','Query')
      attributes = build_attribute_params
      domain = "DomainName=#{@domain}"
      query_params = "QueryExpression=#{query}"
      params = [action,domain,query_params]
      #build request
      response = send_request(params)
      value = translate_query(response)
      raise InvalidRequest.new("Unable to find by query") if value.nil?
      logger.info("find_by_query: exit")
      value
      
    end
    
    private 
    def build_attribute_params
      params = []
      @attributes.each_with_index{|a,i|
        params <<"#{ATTR}.#{i}.Name=#{a[0]}"
        params <<"#{ATTR}.#{i}.Value=#{a[1]}"
        }
      params
    end
    # Translate further the attribute xml block
    # to return a hash
    def translate_attributes(response)
      xml = Hpricot::XML(response)
      h = {}
      (xml/'Attribute').each{|element| h[(element/'Name').inner_text] = (element/'Value').inner_text}
      create_instance_variables(h)
      h
    end
    
    def translate_query(response)
      xml = Hpricot::XML(response)
      (xml/'ItemName').map{|element| element.inner_text}
    end
    
    def create_instance_variables(hash)
      #check if it exists if so just update the value
      hash.each do |k,v|
        name = k
        ivar = "@#{k}"
        inst = self.instance_variable_get(ivar)
        if inst.nil?
          self.instance_variable_set(ivar,v)
          self.class.__send__(:define_method,name,lambda{v})
        else
          inst = v
        end
      end
    end
  end
end