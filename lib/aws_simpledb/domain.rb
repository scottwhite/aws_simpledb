module AWSSimpleDB
  # Domain class to operate crud ops on domains
  class Domain < BaseRequest
    attr_accessor :name, :properties
    
    def initialize
      super
    end
    
    class << self
      def list(number_domains=10, next_token=nil)
        logger.info("list: entry")
        action = ACTION.gsub('VALUE','ListDomains')
        nd = "MaxNumberOfDomains=#{number_domains}"
        nt = "NextToken=#{next_token}" unless next_token.nil?
        params = if nt.nil?
            [action,nd]
          else
            [action,nd,nt]
          end
        #build request
        domain = Domain.new
        response = domain.send_request(params)
        domains = translate(response,'DomainName')
        logger.info("list: exit Have domains #{domains}")
        domains
      end
      
      # Find a domain by array, need better clarity on this at the moment, since
      # a domain is only a string (the name of the domain)
      def find(name)
        domains = list(100)
        index = domains.index(name)
        domains[index] unless index.nil?
      end
      # Delete the domain
      def destroy(name)
        logger.info("destory: entry")
        action = ACTION.gsub('VALUE','DeleteDomain')
        name = "DomainName=#{name}"
        params = [action,name]
        #build request
        domain = Domain.new
        response = domain.send_request(params)
        value = translate(response,'DeleteDomainResponse')
        logger.info("destroy: exit #{value}")
        true
      end
      
    end
    
    
    # Create the domain
    def create
      logger.info("create: entry")
      action = ACTION.gsub('VALUE','CreateDomain')
      name = "DomainName=#{@name}"
      params = [action,name]
      #build request
      response = send_request(params)
      value = self.class.translate(response,'CreateDomainResponse')
      raise InvalidRequest.new("Unable to create domain") if value.nil?
      logger.info("create: exit #{value}")
      @name
    end
      
    # Return the list of properties for this domain
    # this is the meta data for the domain
    def attributes
    end
  end
  
end