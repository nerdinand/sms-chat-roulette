require 'pstore'

class Matches
  PSTORE_PATH = 'sms_chat_roulette.pstore'

  attr_reader :pstore

  def initialize
    @pstore = PStore.new(PSTORE_PATH)

    pstore.transaction do
      pstore[:matches] ||= {}
    end
  end

  def initiate_match(number1, number2)
    logger.info "Creating match between #{number1} and #{number2}"

    pstore.transaction do
      pstore[:matches][number1] = number2
      pstore[:matches][number2] = number1
    end

    logger.info "Current matches: #{matches.size}"
  end

  def logger
    SMSChatRoulette.logger
  end

  def matches
    matches = []

    pstore.transaction(true) do
      matches = pstore[:matches]
    end

    matches
  end

  def delete_match(number)
    logger.info "Deleting match between #{number} and #{old_match}"

    old_match = nil

    pstore.transaction do
      old_match = pstore[:matches].delete number
      pstore[:matches].delete old_match
    end

    logger.info "Current matches: #{matches.size}"

    old_match
  end

  def already_matched?(number)
    matches.key? number
  end

  def match(number)
    matches[number]
  end

  def size
    matches.size
  end
end
