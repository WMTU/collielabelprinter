#!/usr/bin/env ruby
# encoding: utf-8
require "rubygems"
require "bunny"

# Consumer Class for Print Jobs
class ZebraJobConsumer < Bunny::Consumer
  def cancelled?
    @cancelled
  end

  def handle_cancellation(_)
    @cancelled = true
  end
end


PRINTER_NAME = "Zebra_Technologies_ZTC_GK420d"

mq = Bunny.new "amqp://collie:1234@chet.wmtu.local:5672"
mq.start

channel = mq.create_channel
exchange = channel.topic "collie", :auto_delete => true
queue = channel.queue("print_queue").bind(exchange, :routing_key => "print_queue")

print_queue_consumer = ZebraJobConsumer.new(channel, queue)

print_queue_consumer.on_delivery do |delivery_info, metadata, payload|
  puts "Got print job"

  # Build command to print label
  command = %W(lpr -P #{PRINTER_NAME} -o raw)

  process = IO.popen(command, "r+")
  process.write(payload)
  process.close_write()
  Process.wait(process.pid)
  puts "Print queued"
end

queue.subscribe_with(print_queue_consumer, :block => true)
