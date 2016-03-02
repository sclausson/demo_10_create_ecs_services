#!/usr/bin/env ruby
require 'trollop'
require 'aws-sdk-v1'

@opts = Trollop::options do
  opt :stackname, "Name of this CFN stack we are creating now", :type => String, :required => true, :short => "s"
  opt :template, "Name of the CFN template file", :type => String, :required => true, :short => "t"
  opt :region, "AWS region where the stack will be created", :type => String, :required => true, :short => "r"
  opt :cluster_name, "ECS Cluster Name where services will run", :type => String, :required => true
  opt :desired_count_portal, "Number of Portal containers to run on the cluster", :type => String, :default => "1"
  opt :desired_count_weather, "Number of Weather containers to run on the cluster", :type => String, :default => "1"
  opt :desired_count_stockprice, "Number of Stock Price containers to run on the cluster", :type => String, :default => "1"
  opt :task_definition_portal, "Family:Revision of the Portal task definition", :type => String
  opt :task_definition_weather, "Family:Revision of the Weather task definition", :type => String
  opt :task_definition_stockprice, "Family:Revision of the Stock Price task definition", :type => String
end

AWS.config(region: @opts[:region])
cfn = AWS::CloudFormation.new

def parameters 
  parameters = {
    "ClusterName"               => @opts[:cluster_name],
    "DesiredCountPortal"         => @opts[:desired_count_portal],
    "DesiredCountWeather"        => @opts[:desired_count_weather],
    "DesiredCountStockPrice"     => @opts[:desired_count_stockprice],
    "TaskDefinitionPortal"      => @opts[:task_definition_portal],
    "TaskDefinitionWeather"     => @opts[:task_definition_weather],
    "TaskDefinitionStockPrice"  => @opts[:task_definition_stockprice]
  }
  return parameters
end

def template
  file = "./templates/#{@opts[:template]}"
  body = File.open(file, "r").read
  return body
end

cfn.stacks.create(@opts[:stackname], template, parameters: parameters, capabilities: ["CAPABILITY_IAM"])

print "Waiting for stack #{@opts[:stackname]} to complete"

until cfn.stacks[@opts[:stackname]].status == "CREATE_COMPLETE"
  print "."
  sleep 5
end