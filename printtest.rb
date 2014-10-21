#!/usr/bin/env ruby
# encoding: utf-8
require "rubygems"
require "bunny"

mq = Bunny.new "amqp://collie:1234@chet.wmtu.local:5672"
mq.start

channel = mq.create_channel
exchange = channel.topic "collie", :auto_delete => true

for i in 1..1000
  exchange.publish File.open("default.zpl","rb").read, :routing_key => "print_queue"
end

mq.close
