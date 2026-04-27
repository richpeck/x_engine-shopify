require 'net/smtp'

module XEngine
  module SMTP
    class Client
      def self.deliver(log_entry, body_text, settings)
        message = <<~MESSAGE
          From: XEngine <#{settings[:from]}>
          To: #{log_entry.to}
          Subject: #{log_entry.subject}

          #{body_text}
        MESSAGE

        Net::SMTP.start(settings[:address], settings[:port]) do |smtp|
          if settings[:user] && settings[:pass]
            smtp.authenticate(settings[:user], settings[:pass])
          end
          smtp.send_message message, settings[:from], log_entry.to
        end
        
        log_entry.update(status: 'delivered', message_id: SecureRandom.uuid)
      rescue => e
        log_entry.update(status: 'failed', error_message: e.message)
        raise e
      end
    end
  end
end
