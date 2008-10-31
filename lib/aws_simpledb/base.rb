module AWSSimpleDB

  HOST = 'sdb.amazonaws.com'
  #these params are requried in all requests
  SIG = 'Signature=VALUE'
  SIG_VER = 'SignatureVersion=1'
  KEY = 'AWSAccessKeyId=VALUE'
  TIMESTAMP='Timestamp=VALUE'
  VERSION='Version=2007-11-07'
  ACTION = 'Action=VALUE'

  class BaseRequest
    attr_accessor :host, :port, :timeout, :number_retries, :private_key, :public_key
    
    
    def initialize()
      if AWSSimpleDB.const_defined?('CONFIG')
        @timeout = CONFIG[RAILS_ENV]['timeout']
        @host = CONFIG[RAILS_ENV]['host']
        @port = CONFIG[RAILS_ENV]['port']
        @number_retries = CONFIG[RAILS_ENV]['retry'].to_i
        @public_key = CONFIG[RAILS_ENV]['pub_key']
        @private_key = CONFIG[RAILS_ENV]['priv_key']
        @public_key_param = KEY.gsub('VALUE',@public_key)
      else
        raise InvalidConfiguration.new("Unable to retrieve configuration data, is aws.yml setup?")
      end
      @retry = 1
    end
    
        
    def send_request(params)
      logger.info("send_request: entry")
      data = nil
      s_time = Time.now
      begin
        count = (count)?count+1:0
        #build path
        url = build_url_request(params)
        # http = Net::HTTP.new(@host,@port)
        # http.open_timeout = @timeout
        # response,data = http.start{|h_session|
        #   h_session.get2(path)
        # }
        # unless response.is_a?(Net::HTTPSuccess)
        #   raise InvalidResponse.new("Did not get a valid response, #{response.inspect}")
        # end
        data = open(url)
        data = data.read unless data.nil?
        # logger.info("send_request: have response #{response.content_type}")
      rescue Exception => e
        logger.error("send_request: error is #{e.message}")
        if [Timeout::Error].include?(e.class)
          retry if count < @retry
        end
        raise e
      end
      delta = Time.now - s_time
      logger.info("send_request: time taken #{delta}")
      data
    end    
    
    # translate the response by traversing through the doc and finding 
    # all the elements with the target element passed
    # returns an array of values found for the target element
    #   response -> the xml we want to search
    #   element -> the xml tag we want to find values for
    def self.translate(response,element)
      xml = Hpricot::XML(response)
      (xml/element).map{|element| element.inner_text}
    end
    
    private
    # Generate the signature we need to send with the request
    def generate_sig(array_list)
      s = build_string_to_sign(array_list)
      sign_request(s)
    end
    # Encrypt the request params per AWS docs
    # Takes an array_list as the argument which is used
    # to build the sig
    def build_string_to_sign(array_list)
      logger.info("build_string_to_sign: entry")
      temp = {}
      array_list.each{|item|
        a = item.split('=',2)
        temp[a[0].downcase] = a
      }
      # sorted_a = hash.keys.sort{|x,y| x.downcase <=> y.downcase}
      sorted_a = temp.keys.sort
      logger.info("build_string_to_sign: sorted array is #{sorted_a.inspect}")
      unecrypted = sorted_a.map{|item|
          temp[item].join
        }.join
    end
    
    # Sign the string to generate a valid sig
    #   target -> the string to sign
    def sign_request(target)
      digest   = OpenSSL::Digest::Digest.new('sha1')
      encrypted = Base64::encode64(OpenSSL::HMAC.digest(digest, @private_key, target)).strip      
    end
    
    def encode_params(raw_params)
      raw_params.map{|item|
        a = item.split('=',2)
        [a[0],CGI::escape(a[1])].join('=')
        }
    end
    
    # Build the url request to send to AWS
    def build_url_request(params)
      logger.info("build_url_request: params #{params.inspect}")
      #add constants
      params << SIG_VER
      params << VERSION
      #add key
      params << @public_key_param
      #add timestamp
      timestamp_raw = Time.new.utc.xmlschema
      timestamp = TIMESTAMP.gsub('VALUE',timestamp_raw)
      params << timestamp
      #get sig
      raw_sig = generate_sig(params)
      #pop off timestamp so we can re-add encoded
      params.pop
      # need to encode rest of the values
      encoded = encode_params(params)
      #re-add timestamp
      encoded << TIMESTAMP.gsub('VALUE',CGI::escape(timestamp_raw))
      
      sig = CGI::escape(raw_sig)
      #add sig to params
      encoded << SIG.gsub('VALUE',sig)
      #encode the URL
      url = 'http://' + @host + '?' +encoded.join('&')
      logger.info("build_url_request: url is #{url}")
      url
    end
    
  end
end