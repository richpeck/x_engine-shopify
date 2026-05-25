module XEngine
  module SMTP
    class SendEmailNode < XEngine::Core::Node
      # DSL Inputs
      input :recipient_email
      input :subject
      input :body_content
      input :config_group_slug

      def execute
        # 1. Fetch SMTP settings from the group meta
        config_group = XEngine::Group.find_by!(slug: config_group_slug)
        settings = {
          address: config_group.meta['smtp_host'],
          port:    config_group.meta['smtp_port'],
          user:    config_group.meta['smtp_user'],
          pass:    config_group.meta['smtp_pass'],
          from:    config_group.meta['smtp_from'] || 'noreply@xengine.local'
        }

        # 2. Create the log
        log = XEngine::SMTP::EmailLog.create!(
          to: recipient_email,
          subject: subject,
          meta: { workflow_id: workflow.id, node_id: id }
        )

        # 3. Deliver
        XEngine::SMTP::Client.deliver(log, body_content, settings)
      end
    end
  end
end
