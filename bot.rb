require 'active_support/time'
require 'json'
require 'slack-ruby-bot'

class TimeBot < SlackRubyBot::Bot
  command 'what time' do |client, data, match|
    members = TimeBot.channel_members(client, data.channel)
    users_times = members.map { |id| client.web_client.users_info(user: id)[:user] }
      .select { |user| !user[:is_bot] && !user[:deleted] && user[:tz_offset] != nil }
      .map { |user| TimeBot.user_time(client, user) }
    client.web_client.chat_postMessage(channel: data.channel,
                                       text: "#{users_times.join("\n")}",
                                       as_user: true,
                                       parse: "full")
  end
  def TimeBot.channel_members(client, channel)
    begin
      return client.web_client.channels_info(channel: channel)[:channel][:members]
    rescue Slack::Web::Api::Error
      return client.web_client.groups_info(channel: channel)[:group][:members]
    end
  end
  def TimeBot.user_time(client, user)
    offset = user[:tz_offset] / 60 / 60
    tz_label = user[:tz].split("/").last.gsub "_", " "
    timezone = ActiveSupport::TimeZone[offset]
    time = DateTime.now.in_time_zone(timezone)
    formatted_time = time.strftime "%I:%M %p #{tz_label}"
    emoji = TimeBot.clock_emoji(time)
    return "@#{user[:name]} #{emoji} `#{formatted_time}`"
  end
  def TimeBot.clock_emoji(time)
    hour = time.strftime("%l").strip
    return time.strftime ":clock#{hour}:"
  end
end

TimeBot.run
