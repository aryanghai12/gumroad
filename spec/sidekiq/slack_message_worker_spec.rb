# frozen_string_literal: true

require "spec_helper"

describe SlackMessageWorker do
  describe "#perform" do
    let(:room_name) { "payments" }
    let(:sender) { "Test Sender" }
    let(:message) { "Test message" }
    let(:color) { "green" }
    let(:options) { {} }

    before do
      allow(GlobalConfig).to receive(:get)
        .with("NOTIFICATIONS_EMAIL_ADDRESS")
        .and_return("notifications@example.com")
      allow(GlobalConfig).to receive(:get)
        .with("SLACK_WEBHOOK_URL")
        .and_return("https://hooks.slack.com/test")
      allow(Rails.env).to receive(:production?).and_return(true)
    end

    it "always sends email notification" do
      expect(NotificationMailer).to receive(:notification_email)
        .with(room_name, sender, message, color, options)
        .and_return(double(deliver_later: true))

      described_class.new.perform(room_name, sender, message, color, options)
    end

    context "when send_slack_notifications feature is enabled" do
      before do
        allow(Feature).to receive(:active?)
          .with(:send_slack_notifications)
          .and_return(true)
      end

      it "sends to both email and Slack" do
        expect(NotificationMailer).to receive(:notification_email)
          .and_return(double(deliver_later: true))
        expect_any_instance_of(Slack::Notifier).to receive(:ping)

        described_class.new.perform(room_name, sender, message, color, options)
      end
    end

    context "when send_slack_notifications feature is disabled" do
      before do
        allow(Feature).to receive(:active?)
          .with(:send_slack_notifications)
          .and_return(false)
      end

      it "only sends email, skips Slack" do
        expect(NotificationMailer).to receive(:notification_email)
          .and_return(double(deliver_later: true))
        expect(Slack::Notifier).not_to receive(:new)

        described_class.new.perform(room_name, sender, message, color, options)
      end
    end

    it "handles email delivery failures gracefully" do
      allow(NotificationMailer).to receive(:notification_email)
        .and_raise(StandardError, "Email failed")

      expect(Bugsnag).to receive(:notify)
      expect(Rails.logger).to receive(:error).with(/Failed to send notification email/)

      expect {
        described_class.new.perform(room_name, sender, message, color, options)
      }.not_to raise_error
    end

    it "still sends Slack if email fails and feature is enabled" do
      allow(Feature).to receive(:active?)
        .with(:send_slack_notifications)
        .and_return(true)
      allow(NotificationMailer).to receive(:notification_email)
        .and_raise(StandardError, "Email failed")

      expect_any_instance_of(Slack::Notifier).to receive(:ping)

      described_class.new.perform(room_name, sender, message, color, options)
    end

    context "with attachments" do
      let(:options) do
        {
          "attachments" => [
            { "title" => "Report", "text" => "Report link" }
          ]
        }
      end

      it "passes attachments to email" do
        expect(NotificationMailer).to receive(:notification_email)
          .with(room_name, sender, message, color, options)
          .and_return(double(deliver_later: true))
        allow(Feature).to receive(:active?)
          .with(:send_slack_notifications)
          .and_return(false)

        described_class.new.perform(room_name, sender, message, color, options)
      end

      it "passes attachments to Slack when enabled" do
        allow(Feature).to receive(:active?)
          .with(:send_slack_notifications)
          .and_return(true)
        allow(NotificationMailer).to receive(:notification_email)
          .and_return(double(deliver_later: true))

        expect_any_instance_of(Slack::Notifier).to receive(:ping) do |_, _, args|
          expect(args[:attachments].length).to eq(2)
        end

        described_class.new.perform(room_name, sender, message, color, options)
      end
    end

    context "in non-production environments" do
      before do
        allow(Rails.env).to receive(:production?).and_return(false)
      end

      it "routes all messages to test room" do
        expect(NotificationMailer).to receive(:notification_email)
          .with("test", sender, message, color, options)
          .and_return(double(deliver_later: true))

        described_class.new.perform(room_name, sender, message, color, options)
      end
    end
  end
end
