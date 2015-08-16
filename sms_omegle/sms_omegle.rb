require 'byebug'
require 'socket'

require_relative 'message'

HOST = '127.0.0.1'
PORT = 31337

class SMSOmegle
  attr_reader :matches
  attr_reader :match_queue

  COMMANDS = %w(stop)

  STOP_INFORMATION = 'You can always stop the service by sending a "STOP" message.'

  def initialize
    @matches = {}
    @match_queue = []
  end

  def connect
    @socket = TCPSocket.open(HOST, PORT)
  end

  def run
    until @socket.eof? do
      message = @socket.gets

      handle_incoming_sms(Message.from_json(message))
    end
  end

  def handle_incoming_sms(message)
    puts "Handling incoming message: #{message.inspect}"

    if COMMANDS.include? message.text.downcase
      handle_command(message)
    elsif already_matched?(message.sender_recipient)
      send_sms(match(message.sender_recipient), message.text)
    else
      unless match_queue.include? message.sender_recipient
        queue_match(message.sender_recipient)
      end
    end
  end

  def handle_command(message)
    case message.text.downcase
    when 'stop'
      if already_matched? message.sender_recipient
        delete_match(message.sender_recipient)
      else
        match_queue.delete message.sender_recipient
      end
    end
  end

  def delete_match(number)
    old_match = matches.delete number
    matches.delete old_match
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

  def already_matched?(number)
    matches.key? number
  end

  def match(number)
    matches[number]
  end

  def queue_match(number)
    match_queue << number

    send_sms(number, "You\'re now in the queue, waiting to be matched to someone. #{STOP_INFORMATION}")

    if match_queue.size >= 2
      create_match
    end
  end

  def create_match
    number1 = match_queue.pop
    number2 = match_queue.pop

    initiate_match(number1, number2)
  end

  def initiate_match(number1, number2)
    matches[number1] = number2
    matches[number2] = number1

    send_welcome_sms(number1)
    send_welcome_sms(number2)
  end

  def send_welcome_sms(number)
    send_sms(number, "You are now talking to a random stranger. Say hi! #{STOP_INFORMATION}")
  end

  def send_sms(recipient, text)
    message = Message.new(recipient, text)
    puts "Sending: #{message.inspect}"
    @socket.puts(message.to_json)
  end
end
