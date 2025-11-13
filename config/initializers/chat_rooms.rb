# frozen_string_literal: true

CHAT_ROOMS = {
  accounting: {
    slack: { channel: "accounting" },
    email: { name: "Accounting" }
  },
  announcements: {
    slack: { channel: "gumroad-" },
    email: { name: "Announcements" }
  },
  awards: {
    slack: { channel: "gumroad-awards" },
    email: { name: "Awards" }
  },
  internals_log: {
    slack: { channel: "gumroad-" },
    email: { name: "Internals Log" }
  },
  migrations: {
    slack: { channel: "gumroad-" },
    email: { name: "Migrations" }
  },
  payouts: {
    slack: { channel: "gumroad-" },
    email: { name: "Payouts" }
  },
  payments: {
    slack: { channel: "accounting" },
    email: { name: "Payments" }
  },
  risk: {
    slack: { channel: "gumroad-" },
    email: { name: "Risk" }
  },
  test: {
    slack: { channel: "test" },
    email: { name: "Test" }
  },
  iffy_log: {
    slack: { channel: "gumroad-iffy-log" },
    email: { name: "Iffy Log" }
  },
}.freeze
