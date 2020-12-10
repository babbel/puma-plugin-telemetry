# frozen_string_literal: true

RSpec.describe Puma::Plugin::Telemetry do
  it "has a version number" do
    expect(Puma::Plugin::Telemetry::VERSION).not_to be_nil
  end

  describe ".config" do
    it "has a default configuration" do
      expect(described_class.config).not_to be_nil
    end
  end

  describe ".build" do
    it "returns telemetry hash" do
      expect(described_class.build).to eq({})
    end
  end
end

RSpec.describe Puma::Plugins.find("telemetry") do
  describe "plugin registration" do
    it "works" do
      is_expected.to respond_to(:start)
    end
  end

  describe ".call" do
    let(:config) do
      Puma::Plugin::Telemetry::Config.new.tap do |c|
        c.targets = targets
      end
    end

    let(:targets) { [double("target1"), double("target2")] }
    let(:telemetry) { { foo: :bar } }

    before do
      allow(Puma::Plugin::Telemetry).to receive(:config).and_return(config)
    end

    it "executes targets with telemetry" do
      expect(targets[0]).to receive(:call).with(telemetry)
      expect(targets[1]).to receive(:call).with(telemetry)

      expect(subject.call(telemetry)).to eq(targets)
    end
  end
end
