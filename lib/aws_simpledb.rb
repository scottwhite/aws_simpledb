require 'rubygems'
require 'rest-open-uri'
require 'cgi'
require 'openssl'
require 'digest/sha1'
require 'base64'
require 'time'
require 'logger'
require 'hpricot'


require File.dirname(__FILE__) + '/aws_simpledb/error'
require File.dirname(__FILE__) + '/aws_simpledb/base'
require File.dirname(__FILE__) + '/aws_simpledb/domain'
require File.dirname(__FILE__) + '/aws_simpledb/item'


def logger
  @logger ||= if Module.constants.include?('RAILS_DEFAULT_LOGGER')
                RAILS_DEFAULT_LOGGER
              else
                Logger.new('aws_simpledb.log')
              end
end