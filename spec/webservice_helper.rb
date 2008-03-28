require 'rubygems'
require 'mongrel'
require 'logger'

class FakeSoapHTTPService
  attr_accessor :listener # Mongrel callback - accepts the HttpServer
  attr_reader :request_notify  

  def process(request, response)
    logger.info(request)
    case request.params['REQUEST_URI']
    when '/aws/longwait';
      sleeptime = 30
    when '/aws';
      sleeptime = 3
    end
   response.start(200) do |head, out|
     msg = request.body.read(request.body.size)
     logger.info(msg)
     sleep sleeptime
       head['Content-Type'] = "text/xml"
       out.write(msg)
    end      
  end
  
  def logger
    @logger ||= Logger.new('test_mock_crm_service_log')
  end  
end