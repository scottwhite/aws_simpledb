require 'rubygems'
require 'spec'
require 'time'
require File.dirname(__FILE__) + '/../lib/aws_simpledb'
require File.dirname(__FILE__) + '/webservice_helper'

KEYS = YAML::load(File.open(File.dirname(__FILE__) +'/aws_keys.yml'))

describe "creating a signed request" do
  
  it "should sign the request" do
    pending
  end
  
  it "should raise an InvalidRequestError" do
    pending
  end  
end

describe "working with domains" do
  before(:each) do
    stub_config(10,'sdb.amazonaws.com',KEYS['pub'],KEYS['priv'])
    @domain_name = 'foobar'
  end
  it "should create a domain" do
    domain = AWSSimpleDB::Domain.new
    domain.name = @domain_name
    domain.create
    AWSSimpleDB::Domain.list.include?(domain.name).should be_true
  end
  
  it "should lists domains" do
    domains = AWSSimpleDB::Domain.list
    domains.should have_at_least(2).item
  end
  
  it "should find a domain by name" do
    domain = AWSSimpleDB::Domain.find(@domain_name)
    domain.should == @domain_name
  end
  
  it "should return a list of attributes for a domain" do
    pending "it should but doesn't"
    domain = AWSSimpleDB::Domain.find(@domain_name)
    domain.attributes.should have_at_least(1).item
  end

  it "should delete a domain(s)" do
    AWSSimpleDB::Domain.destroy(@domain_name)
    AWSSimpleDB::Domain.find(@domain_name).should be_nil
  end

end
describe "working with attributes" do
  before(:each) do
    stub_config(10,'sdb.amazonaws.com',KEYS['pub'],KEYS['priv'])
        @domain_name = 'foobar'
    domain = AWSSimpleDB::Domain.new
    domain.name = @domain_name
    domain.create
    @item_name = 'test100'
  end
  
  
  
  it "should create methods for added attributes" do
    item = AWSSimpleDB::Item.new
    item << {'first_name','bob'}
    item << {'last_name','smith'}
    item << {'age',50}
    item << {'color','blue'}
    time = Time.now
    item << {'dob',time.utc.xmlschema}
    item.dob.should == time.utc.xmlschema
    item.first_name.should == 'bob'
    item.color.should == 'blue'
    item.age.should == 50
  end
  
  it "should put attributes for an item name" do
    item = AWSSimpleDB::Item.new
    item.domain=@domain_name
    item.name= @item_name
    item << {'first_name','bob'}
    item << {'last_name','smith'}
    item << {'age',100}
    item << {'color','blue'}
    time = Time.now    
    item << {'dob',time.utc.xmlschema}
    name = item.create
    name.should == @item_name
  end

  it "should retrieve a list for an item name" do
    item = AWSSimpleDB::Item.new
    item.domain=@domain_name
    item.name = @item_name
    item.list.should have_at_least(1).item
    item.color.should == 'blue'
    item.age.should == '100'
    item.first_name.should == 'bob'
    item.last_name.should == 'smith'
  end
  
  it "should remove attributes for an item name" do
    item = AWSSimpleDB::Item.new
    item.domain=@domain_name
    item.name = @item_name
    item.delete.should_not be_nil
  end
  
end

describe "working with attributes" do
  before(:each) do
    stub_config(10,'sdb.amazonaws.com',KEYS['pub'],KEYS['priv'])
    color=['blue','green','yellow','red','orange']
    @domain_name = 'foobar'
    item = AWSSimpleDB::Item.new
    item.domain=@domain_name
    
    (1..4).each do |i|
      item.name= "test_auto#{i}"
      item << {'first_name',"bob#{i}"}
      if i > 2 
        item << {'last_name',"super-star#{i}"}
      else
        item << {'last_name','super-star'}
      end
      item << {'age',rand(100)}
      item << {'color',color[rand(color.size)]}
      item << {'dob',Time.now.utc.xmlschema}
      item.create
    end
  end
  
  after(:each) do
    domain_name = 'foobar'
    item = AWSSimpleDB::Item.new
    item.domain=domain_name
    (1..4).each do |i|
      item.name = "test_auto#{i}"
      item.delete
    end
  end
  
  it "should find by query expression" do
    item = AWSSimpleDB::Item.new
    item.domain=@domain_name
    # sleep 3  # have to wait for simpledb to catch up
    values = item.find_by_query("['first_name' = 'bob1']")
    values.should have(1).items
  end
  
  it "should find by query expression for date" do
    item = AWSSimpleDB::Item.new
    item.domain=@domain_name
    # sleep 3  # have to wait for simpledb to catch up
    values = item.find_by_query("['dob'>'2008-01-15']")
    # values = item.find_by_query("['dob'='']")    
    values.should have(4).items
  end
  
end


def stub_config(timeout,host,pub_key,priv_key,port=80)
  config = {'spec'=>{'host'=>host,'port'=>port,'timeout'=>timeout,'pub_key'=>pub_key,'priv_key'=>priv_key, 'retry'=>1}}
  AWSSimpleDB.const_set('CONFIG',config) #unless AWSSimpleDB.const_defined?('CONFIG')
  AWSSimpleDB.const_set('RAILS_ENV','spec') #unless AWSSimpleDB.const_defined?('RAILS_ENV')
end

def start_server
  server = Mongrel::HttpServer.new('0.0.0.0', 54321)
  server.register("/aws", FakeSoapHTTPService.new)
  server.run
  sleep 2
  server
end