# frozen_string_literal: true

module Onetime
  class RemoveSlackIntegration
    def self.call
      new.call
    end

    def call
      puts "🚀 Starting Slack code removal process..."
      puts ""

      remove_slack_from_worker
      remove_slack_from_chat_rooms
      remove_feature_flag
      remove_slack_gem_from_gemfile

      puts ""
      puts "✅ Slack code removal complete!"
      puts "✅ Feature flag removed"
      puts "✅ Gemfile updated (review slack-notifier removal)"
      puts ""
      puts "📝 Next steps:"
      puts "1. Review changes: git diff"
      puts "2. Run: bundle install"
      puts "3. Restart server/workers"
      puts "4. Commit: git commit -am 'chore: remove Slack integration'"
      puts ""
    end

    private
      def remove_slack_from_worker
        worker_file = Rails.root.join("app/sidekiq/slack_message_worker.rb")

        unless File.exist?(worker_file)
          puts "⚠️  SlackMessageWorker not found"
          return
        end

        File.read(worker_file)

        new_content = <<~RUBY
        # frozen_string_literal: true

        class SlackMessageWorker
          include Sidekiq::Job
          sidekiq_options retry: 9, queue: :default

          def perform(room_name, sender, message_text, color = "gray", options = {})
            room_name = "test" unless Rails.env.production?

            NotificationMailer.notification_email(
              room_name,
              sender,
              message_text,
              color,
              options
            ).deliver_later
          rescue StandardError => e
            Rails.logger.error("Failed to send notification email: \#{e.message}")
            Bugsnag.notify(e, {
                             room_name: room_name,
                             sender: sender,
                             message_preview: message_text&.first(100)
                           })
          end
        end
        RUBY

        File.write(worker_file, new_content)
        puts "✅ Updated SlackMessageWorker (removed Slack code)"
      end

      def remove_slack_from_chat_rooms
        config_file = Rails.root.join("config/initializers/chat_rooms.rb")

        unless File.exist?(config_file)
          puts "⚠️  chat_rooms.rb not found"
          return
        end

        File.read(config_file)

        new_content = <<~RUBY
        # frozen_string_literal: true

        CHAT_ROOMS = {
          accounting: {
            email: { name: "Accounting" }
          },
          announcements: {
            email: { name: "Announcements" }
          },
          awards: {
            email: { name: "Awards" }
          },
          internals_log: {
            email: { name: "Internals Log" }
          },
          migrations: {
            email: { name: "Migrations" }
          },
          payouts: {
            email: { name: "Payouts" }
          },
          payments: {
            email: { name: "Payments" }
          },
          risk: {
            email: { name: "Risk" }
          },
          test: {
            email: { name: "Test" }
          },
          iffy_log: {
            email: { name: "Iffy Log" }
          },
        }.freeze
        RUBY

        File.write(config_file, new_content)
        puts "✅ Updated CHAT_ROOMS (removed Slack config)"
      end

      def remove_feature_flag
        if Feature.exists?(:send_slack_notifications)
          Feature.remove(:send_slack_notifications)
          puts "✅ Removed send_slack_notifications feature flag"
        else
          puts "ℹ️  Feature flag send_slack_notifications not found (already removed or never existed)"
        end
      rescue => e
        puts "⚠️  Could not remove feature flag: #{e.message}"
        puts "   You may need to remove it manually from your feature flag system"
      end

      def remove_slack_gem_from_gemfile
        gemfile_path = Rails.root.join("Gemfile")

        unless File.exist?(gemfile_path)
          puts "⚠️  Gemfile not found"
          return
        end

        content = File.read(gemfile_path)
        original_content = content.dup

        # Remove slack-notifier gem lines
        content.gsub!(/^\s*gem\s+['"]slack-notifier['"].*$\n?/, "")

        if content != original_content
          File.write(gemfile_path, content)
          puts "✅ Removed slack-notifier from Gemfile"
        else
          puts "ℹ️  slack-notifier not found in Gemfile (already removed or never added)"
        end
      end
  end
end
