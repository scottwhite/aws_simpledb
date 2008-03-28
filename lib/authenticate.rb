module AWS
  #Ripped wholly from AWS::S3 gem
  module Authenicate
    
    def canonical_string            
      options = {}
      options[:expires] = expires if expires?
      CanonicalString.new(request, options)
    end
    memoized :canonical_string

    def encoded_canonical
      digest   = OpenSSL::Digest::Digest.new('sha1')
      b64_hmac = Base64.encode64(OpenSSL::HMAC.digest(digest, secret_access_key, canonical_string)).strip
      url_encode? ? CGI.escape(b64_hmac) : b64_hmac
    end
    
    def url_encode?
      !@options[:url_encode].nil?
    end
    
    
    
     # The CanonicalString is used to generate an encrypted signature, signed with your secrect access key. It is composed of 
      # data related to the given request for which it provides authentication. This data includes the request method, request headers,
      # and the request path. Both Header and QueryString use it to generate their signature.
      class CanonicalString < String #:nodoc:
        class << self
          def default_headers
            %w(content-type content-md5)
          end

          def interesting_headers
            ['content-md5', 'content-type', 'date', amazon_header_prefix]
          end
          
          def amazon_header_prefix
            /^#{AMAZON_HEADER_PREFIX}/io
          end
        end
        
        attr_reader :request, :headers
        
        def initialize(request, options = {})
          super()
          @request = request
          @headers = {}
          @options = options
          # "For non-authenticated or anonymous requests. A NotImplemented error result code will be returned if 
          # an authenticated (signed) request specifies a Host: header other than 's3.amazonaws.com'"
          # (from http://docs.amazonwebservices.com/AmazonS3/2006-03-01/VirtualHosting.html)
          request['Host'] = DEFAULT_HOST
          build
        end
    
        private
          def build
            self << "#{request.method}\n"
            ensure_date_is_valid
            
            initialize_headers
            set_expiry!
        
            headers.sort_by {|k, _| k}.each do |key, value|
              value = value.to_s.strip
              self << (key =~ self.class.amazon_header_prefix ? "#{key}:#{value}" : value)
              self << "\n"
            end
            self << path
          end
      
          def initialize_headers
            identify_interesting_headers
            set_default_headers
          end
          
          def set_expiry!
            self.headers['date'] = @options[:expires] if @options[:expires]
          end
          
          def ensure_date_is_valid
            request['Date'] ||= Time.now.httpdate
          end

          def identify_interesting_headers
            request.each do |key, value|
              key = key.downcase # Can't modify frozen string so no bang
              if self.class.interesting_headers.any? {|header| header === key}
                self.headers[key] = value.to_s.strip
              end
            end
          end

          def set_default_headers
            self.class.default_headers.each do |header|
              self.headers[header] ||= ''
            end
          end

          def path
            [only_path, extract_significant_parameter].compact.join('?')
          end
          
          def extract_significant_parameter
            request.path[/[&?](acl|torrent|logging)(?:&|=|$)/, 1]
          end
          
          def only_path
            request.path[/^[^?]*/]
          end
      end
    end
  end
end