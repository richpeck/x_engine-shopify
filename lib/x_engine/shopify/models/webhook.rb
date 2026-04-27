



module XEngine
  module SMTP
    class EmailLog < XEngine::Base
      # Set dynamic table name or default
      self.table_name = 'x_engine_smtp_logs'
      
      validates :to, presence: true
      
      scope :failed, -> { where(status: 'failed') }
      scope :delivered, -> { where(status: 'delivered') }
    end
  end
end
