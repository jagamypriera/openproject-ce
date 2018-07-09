require 'spec_helper'

describe ::Webhooks::Webhook, type: :model do
  subject { FactoryGirl.build :webhook }

  describe 'attributes' do
    describe '#url' do
      it 'accepts http' do
        subject.url = 'http://foo.example.org'
        expect(subject).to be_valid
      end

      it 'accepts http' do
        subject.url = 'https://foo.example.org'
        expect(subject).to be_valid
      end

      it 'accepts other schemas' do
        subject.url = 'ftp://foo.example.org'
        expect(subject).not_to be_valid
        expect(subject.errors).to have_key(:url)
      end
    end
  end

  describe '#events' do
    let(:events) { %w(work_package:updated work_package:created) }
    before do
      subject.event_names = events
      subject.save!
    end

    it 'has an event association' do
      expect(subject.events.count).to eq 2
      expect(subject.event_names).to eq events
    end

    it 'finds the webhook with the saved events' do
      expect(described_class.with_event_name(events[0]).first).to eq(subject)
      expect(described_class.with_event_name(events[1]).first).to eq(subject)
    end
  end

  describe '#projects' do
    let(:project1) { FactoryGirl.create :project }

    before do
      subject.projects << project1
      subject.save!
    end

    it 'has an event association' do
      expect(subject.projects.count).to eq 1
      expect(subject.project_ids).to eq([project1.id])
    end
  end
end