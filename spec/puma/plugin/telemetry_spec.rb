# frozen_string_literal: true

RSpec.describe Puma::Plugin::Telemetry do
  it "has a version number" do
    expect(Puma::Plugin::Telemetry::VERSION).not_to be nil
  end
end
