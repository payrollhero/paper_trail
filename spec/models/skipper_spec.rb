# frozen_string_literal: true

require "spec_helper"

RSpec.describe Skipper, type: :model, versioning: true do
  it { is_expected.to be_versioned }

  describe "#update!", versioning: true do
    context "when updating a skipped attribute" do
      let(:t1) { Time.zone.local(2015, 7, 15, 20, 34, 0) }
      let(:t2) { Time.zone.local(2015, 7, 15, 20, 34, 30) }

      it "does not create a version" do
        skipper = Skipper.create!(another_timestamp: t1)
        expect {
          skipper.update!(another_timestamp: t2)
        }.not_to(change { skipper.versions.length })
      end
    end
  end

  describe "#touch" do
    let(:t1) { Time.zone.local(2015, 7, 15, 20, 34, 0) }
    let(:t2) { Time.zone.local(2015, 7, 15, 20, 34, 30) }

    if ActiveRecord.gem_version >= Gem::Version.new("6")
      it "does not create a version for skipped attributes" do
        skipper = Skipper.create!(another_timestamp: t1)
        expect {
          skipper.touch(:another_timestamp, time: t2)
        }.not_to(change { skipper.versions.length })
      end

      it "does not create a version for ignored attributes" do
        skipper = Skipper.create!(created_at: t1)
        expect {
          skipper.touch(:created_at, time: t2)
        }.not_to(change { skipper.versions.length })
      end
    else
      it "creates a version even for skipped attributes" do
        skipper = Skipper.create!(another_timestamp: t1)
        expect {
          skipper.touch(:another_timestamp, time: t2)
        }.to(change { skipper.versions.length })
      end

      it "creates a version even for ignored attributes" do
        skipper = Skipper.create!(created_at: t1)
        expect {
          skipper.touch(:created_at, time: t2)
        }.to(change { skipper.versions.length })
      end
    end

    it "creates a version for non-skipped timestamps" do
      skipper = Skipper.create!
      expect {
        skipper.touch
      }.to(change { skipper.versions.length })
    end
  end

  describe "#reify" do
    let(:t1) { Time.zone.local(2015, 7, 15, 20, 34, 0) }
    let(:t2) { Time.zone.local(2015, 7, 15, 20, 34, 30) }

    context "without preserve (default)" do
      it "has no timestamp" do
        skipper = Skipper.create!(another_timestamp: t1)
        skipper.update!(another_timestamp: t2, name: "Foobar")
        skipper = skipper.versions.last.reify
        expect(skipper.another_timestamp).to be(nil)
      end
    end

    context "with preserve" do
      it "preserves its timestamp" do
        skipper = Skipper.create!(another_timestamp: t1)
        skipper.update!(another_timestamp: t2, name: "Foobar")
        skipper = skipper.versions.last.reify(unversioned_attributes: :preserve)
        expect(skipper.another_timestamp).to eq(t2)
      end
    end
  end
end
