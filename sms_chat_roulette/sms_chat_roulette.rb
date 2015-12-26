require 'byebug'

require 'thor'
require 'socket'
require 'logger'

require_relative 'config'
require_relative 'cli'
require_relative 'matches'
require_relative 'message'

class SMSChatRoulette
  attr_reader :matches, :match_queue, :host, :port, :socket

  COMMANDS = %w(stop)

  STOP_INFORMATION = 'You can always stop the service by sending a "STOP" message.'

  def self.logger
    @@logger ||= Logger.new(STDOUT)
  end

  def initialize(host, port)
    @host = host
    @port = port
    @matches = Matches.new
    @match_queue = []
  end

  def connect
    @socket = TCPSocket.open(host, port)
  end

  def run
    until socket.eof? do
      message = socket.gets

      handle_incoming_sms(Message.from_json(message))
    end
  end

  def handle_incoming_sms(message)
    SMSChatRoulette.logger.info "<--     #{message}"

    if COMMANDS.include? message.text.downcase
      handle_command(message)
    elsif matches.already_matched?(message.sender_recipient)
      forward_message(message)
    else
      unless match_queue.include? message.sender_recipient
        queue_match(message.sender_recipient)
      end
    end
  end

  def forward_message
    match = matches.match(message.sender_recipient)
    SMSChatRoulette.logger.info "Forwarding #{message} to #{match}"
    send_sms(match, message.text)
  end

  def handle_command(message)
    case message.text.downcase
    when 'stop'
      if matches.already_matched? message.sender_recipient
        delete_match(message.sender_recipient)
      else
        match_queue.delete message.sender_recipient
      end
    end
  end

  def delete_match(number)
    old_match = matches.delete_match(number)
    match_queue << old_match

    notify_unsubscribed(number)
    notify_unmatched(old_match)
  end

  def notify_unsubscribed(number)
    send_sms(number, "You have been unsubscribed from the service.")
  end

  def notify_unmatched(number)
    send_sms(number, "Your match has left the conversation. You are back in the queue. #{STOP_INFORMATION}")
  end

  def queue_match(number)
    match_queue << number

    send_sms(number, "You\'re now in the queue, waiting to be matched to someone. #{STOP_INFORMATION}")

    if match_queue.size >= 2
      create_match
      SMSChatRoulette.logger.info "Current matches: #{matches.size}"
    end
  end

  def create_match
    number1 = match_queue.pop
    number2 = match_queue.pop

    matches.initiate_match(number1, number2)

    send_welcome_sms(number1)
    send_welcome_sms(number2)
  end

  def send_welcome_sms(number)
    send_sms(number, "You are now talking to a random stranger. Say hi! #{STOP_INFORMATION}")
  end

  def send_sms(recipient, text)
    message = Message.new(recipient, text)
    SMSChatRoulette.logger.info "    --> #{message}"
    socket.puts(message.to_json)
  end
end
