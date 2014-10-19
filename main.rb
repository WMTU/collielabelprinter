#!/usr/bin/env ruby
# encoding: utf-8
require "rubygems"
require "bunny"
require "logger"
require "yaml"

# Load configuration settings
CONFIG = YAML.load_file('config.yml')

# Setup logger
logger = Logger.new(STDOUT)
logger.level = Logger::WARN

# Consumer Class for Print Jobs
class ZebraJobConsumer < Bunny::Consumer
  def cancelled?
    @cancelled
  end

  def handle_cancellation(_)
    @cancelled = true
  end
end

# Setup RabbitMQ connection
mq = Bunny.new "amqp://#{CONFIG["RABBITMQ"]["USER"]}:#{CONFIG["RABBITMQ"]["PASS"]}@#{CONFIG["RABBITMQ"]["HOST"]}:#{CONFIG["RABBITMQ"]["PORT"]}"
mq.start

channel = mq.create_channel
exchange = channel.topic "collie", :auto_delete => true
queue = channel.queue("print_queue").bind(exchange, :routing_key => "print_queue")

print_queue_consumer = ZebraJobConsumer.new(channel, queue)

print_queue_consumer.on_delivery do |delivery_info, metadata, payload|
  logger.info "Got print job"

  # Build command to print label
  command = %W(lpr -P #{CONFIG["CUPS_PRINTER_NAME"]} -o raw)

  process = IO.popen(command, "r+")
  process.write(payload)
  process.close_write()
  Process.wait(process.pid)
  logger.info "Print queued"
end

queue.subscribe_with(print_queue_consumer, :block => true)
