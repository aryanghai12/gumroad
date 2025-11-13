# frozen_string_literal: true

require "spec_helper"

describe NotificationMailer do
  describe "#notification_email" do
    let(:room_name) { "payments" }
    let(:sender) { "PayPal Top-up" }
    let(:message) { "PayPal balance needs to be $200,000.00" }
    let(:color) { "red" }
    let(:notification_email) { "notifications@example.com" }

    before do
      # Stub GlobalConfig with fallback for any key
      allow(GlobalConfig).to receive(:get).and_call_original
      allow(GlobalConfig).to receive(:get)
        .with("NOTIFICATIONS_EMAIL_ADDRESS")
        .and_return(notification_email)
      allow(GlobalConfig).to receive(:get)
        .with("MAILER_HEADERS_ENCRYPTION_KEY_V1")
        .and_return("test_encryption_key_123")
    end

    it "creates email with correct subject format" do
      mail = described_class.notification_email(room_name, sender, message, color)

      expect(mail.subject).to eq("[Gumroad Notifications][Payments] PayPal Top-up")
      expect(mail.from).to eq([ApplicationMailer::NOREPLY_EMAIL])
      expect(mail.to).to eq([notification_email])
    end

    it "includes message text in body" do
      mail = described_class.notification_email(room_name, sender, message, color)

      expect(mail.html_part.body.raw_source).to include(message)
      expect(mail.html_part.body.raw_source).to include(sender)
    end

    it "formats attachments correctly" do
      options = {
        "attachments" => [
          { "title" => "Report", "text" => "Link to report" }
        ]
      }

      mail = described_class.notification_email(room_name, sender, message, color, options)

      expect(mail.html_part.body.raw_source).to include("Report: Link to report")
    end

    it "handles multiple attachments" do
      options = {
        "attachments" => [
          { "title" => "Report 1", "text" => "First report" },
          { "title" => "Report 2", "text" => "Second report" }
        ]
      }

      mail = described_class.notification_email(room_name, sender, message, color, options)

      expect(mail.html_part.body.raw_source).to include("Report 1: First report")
      expect(mail.html_part.body.raw_source).to include("Report 2: Second report")
    end

    it "handles missing email address gracefully" do
      allow(GlobalConfig).to receive(:get)
        .with("NOTIFICATIONS_EMAIL_ADDRESS")
        .and_return(nil)

      mail = described_class.notification_email(room_name, sender, message, color)

      expect(mail.message).to be_a(ActionMailer::Base::NullMail)
    end

    it "handles blank email address gracefully" do
      allow(GlobalConfig).to receive(:get)
        .with("NOTIFICATIONS_EMAIL_ADDRESS")
        .and_return("")

      mail = described_class.notification_email(room_name, sender, message, color)

      expect(mail.message).to be_a(ActionMailer::Base::NullMail)
    end

    it "handles invalid room name gracefully" do
      mail = described_class.notification_email("invalid_room", sender, message, color)

      expect(mail.message).to be_a(ActionMailer::Base::NullMail)
    end

    context "different chat rooms" do
      {
        accounting: "Accounting",
        announcements: "Announcements",
        awards: "Awards",
        payments: "Payments",
        risk: "Risk"
      }.each do |room_key, room_name|
        it "uses correct room name for #{room_key}" do
          mail = described_class.notification_email(room_key.to_s, sender, message, color)

          expect(mail.subject).to include("[#{room_name}]")
        end
      end
    end

    context "different colors" do
      %w[gray green red hotpink yellow blue].each do |test_color|
        it "handles #{test_color} color" do
          mail = described_class.notification_email(room_name, sender, message, test_color)

          expect(mail.html_part.body.raw_source).to be_present
        end
      end
    end

    it "generates both HTML and text versions" do
      mail = described_class.notification_email(room_name, sender, message, color)

      expect(mail.html_part.body.raw_source).to include(message)
      expect(mail.text_part.body.raw_source).to include(message)
    end
  end
end
