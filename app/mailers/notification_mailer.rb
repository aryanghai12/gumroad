# frozen_string_literal: true

class NotificationMailer < ApplicationMailer
  skip_after_action :validate_from_email_domain!, only: [:notification_email]

  def notification_email(room_name, sender, message_text, color = "gray", options = {})
    @sender = sender
    @message_text = message_text
    @color = color
    @attachments_text = format_attachments(options["attachments"])

    chat_room = CHAT_ROOMS[room_name.to_sym]
    return unless chat_room

    room_display_name = chat_room[:email][:name]
    notification_email = options[:preview_email] || GlobalConfig.get("NOTIFICATIONS_EMAIL_ADDRESS")

    return unless notification_email.present?

    subject = "[Gumroad Notifications][#{room_display_name}] #{sender}"

    mail(
      from: ApplicationMailer::NOREPLY_EMAIL,
      to: notification_email,
      subject: subject,
      delivery_method_options: options[:preview_email] ? preview_delivery_options : nil
    )
  end

  private
    def preview_delivery_options
      {
        address: "smtp.sendgrid.net",
        domain: "gumroad.com",
        user_name: "preview",
        password: "preview"
      }
    end

    def format_attachments(attachments)
      return nil if attachments.nil? || attachments.empty?

      attachments.map do |attachment|
        "#{attachment['title']}: #{attachment['text']}"
      end.join("\n\n")
    end

    def color_to_hex(color_name)
      color_map = {
        "gray" => "#808080",
        "green" => "#28a745",
        "red" => "#dc3545",
        "hotpink" => "#ff69b4",
        "yellow" => "#ffc107",
        "blue" => "#007bff"
      }
      color_map[color_name] || "#808080"
    end

    helper_method :color_to_hex
end
