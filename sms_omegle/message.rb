require 'json'

class Message
  attr_reader :sender_recipient, :text

  def initialize(sender_recipient, text)
    @sender_recipient = sender_recipient
    @text = text
  end

  def self.from_json(json_string)
    hash = JSON.parse(json_string)
    Message.new(hash['sender_recipient'], hash['text'])
  end

  def to_json
    JSON.generate({
      sender_recipient: sender_recipient,
      text: text
    })
  end
end
