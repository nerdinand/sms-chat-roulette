class Cli < Thor

  desc 'start', 'starts the SMS Chat Roulette'
  def start
    system "adb forward tcp:#{Config::ROULETTE_PORT} tcp:#{Config::GATEWAY_DEVICE_PORT}"

    sms_chat_roulette = SMSChatRoulette.new(Config::HOST, Config::ROULETTE_PORT)
    sms_chat_roulette.connect

    # number_sample = ["6843", "6546", "4095", "2674", "4336", "6000", "5511", "7180", "7670", "8023", "6376", "7150", "5405", "8184", "3564", "8476", "2643", "2736", "3113", "9030", "4110", "6293", "3524", "2269", "4269", "4884", "7669", "6454", "2337", "2984", "4781", "2770", "4488", "6809", "8524", "3090", "9513", "8500", "4012", "9242", "8899", "5813", "7350", "7414", "3867", "2302", "7636", "2733", "6452", "3738", "8837", "4058", "3215", "9194", "4420", "8442", "2018", "9446", "5959", "2362", "5038", "4865", "4527", "8163", "8768", "8448", "7701", "5051", "2380", "5970", "4564", "7821", "7454", "8193", "4257", "3272", "2393", "7484", "6003", "2276", "2157", "4847", "3233", "9436", "6363", "5352", "6366", "5534", "8783", "8956", "6375", "3583", "4126", "4999", "3987", "7768", "5262", "2653", "4712", "4322"]

    # number_sample.each do |number|
    #   sms_chat_roulette.send_sms(number, 'Chat roulette now on this number! Type something to be matched to someone!')
    # end

    sms_chat_roulette.run
  end
end
