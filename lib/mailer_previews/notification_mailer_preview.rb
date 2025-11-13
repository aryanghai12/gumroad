# frozen_string_literal: true

class NotificationMailerPreview < ActionMailer::Preview
  def notification_email_simple
    with_preview_config do
      NotificationMailer.notification_email(
        "payments",
        "PayPal Top-up",
        "PayPal balance needs to be $200,000.00",
        "red",
        { preview_email: "notifications-preview@gumroad.com" }
      )
    end
  end

  def notification_email_with_attachments
    with_preview_config do
      NotificationMailer.notification_email(
        "risk",
        "Fraud Alert",
        "Suspicious activity detected on purchase #123456",
        "hotpink",
        {
          "attachments" => [
            { "title" => "Purchase Details", "text" => "Amount: $1,500 | Location: Nigeria" },
            { "title" => "User Info", "text" => "Email: suspicious@example.com | IP: 192.168.1.1" }
          ],
          preview_email: "notifications-preview@gumroad.com"
        }
      )
    end
  end

  def notification_email_accounting
    with_preview_config do
      NotificationMailer.notification_email(
        "accounting",
        "Stripe Payout",
        "Daily payout completed: $50,000.00 transferred to bank account",
        "green",
        { preview_email: "notifications-preview@gumroad.com" }
      )
    end
  end

  def notification_email_awards
    with_preview_config do
      NotificationMailer.notification_email(
        "awards",
        "New Milestone",
        "Creator johndoe just hit $100,000 in sales! 🎉",
        "yellow",
        { preview_email: "notifications-preview@gumroad.com" }
      )
    end
  end

  private
    def with_preview_config
      env_vars = {
        "MAILER_HEADERS_ENCRYPTION_KEY_V1" => "preview_encryption_key_12345678",
        "SENDGRID_SMTP_ADDRESS" => "smtp.sendgrid.net",
        "SENDGRID_GUMROAD_TRANSACTIONS_API_KEY" => "preview_key",
        "SENDGRID_GUMROAD_FOLLOWER_CONFIRMATION_API_KEY" => "preview_key",
        "SENDGRID_GR_CREATORS_API_KEY" => "preview_key",
        "SENDGRID_GR_CUSTOMERS_API_KEY" => "preview_key",
        "SENDGRID_GR_CUSTOMERS_LEVEL_2_API_KEY" => "preview_key",
        "RESEND_SMTP_ADDRESS" => "smtp.resend.com",
        "RESEND_DEFAULT_API_KEY" => "preview_key",
        "RESEND_FOLLOWERS_API_KEY" => "preview_key",
        "RESEND_CREATORS_API_KEY" => "preview_key",
        "RESEND_CUSTOMERS_API_KEY" => "preview_key",
        "RESEND_CUSTOMERS_LEVEL_2_API_KEY" => "preview_key"
      }

      original_values = {}
      env_vars.each do |key, value|
        original_values[key] = ENV.fetch(key, nil)
        ENV[key] = value
      end

      result = yield

      env_vars.each_key do |key|
        if original_values[key].nil?
          ENV.delete(key)
        else
          ENV[key] = original_values[key]
        end
      end

      result
    end
end
