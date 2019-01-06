# frozen_string_literal: true

RSpec.describe Scim::Kit::V2::Resource do
  subject { described_class.new(schema: schema, location: resource_location) }

  let(:schema) { Scim::Kit::V2::Schema.new(id: 'User', name: 'User', location: FFaker::Internet.uri('https')) }
  let(:resource_location) { FFaker::Internet.uri('https') }

  context 'with common attributes' do
    let(:id) { SecureRandom.uuid }
    let(:external_id) { SecureRandom.uuid }
    let(:created_at) { Time.now }
    let(:updated_at) { Time.now }
    let(:version) { SecureRandom.uuid }

    before do
      subject.id = id
      subject.external_id = external_id
      subject.meta.created = created_at
      subject.meta.last_modified = updated_at
      subject.meta.version = version
    end

    specify { expect(subject.id).to eql(id) }
    specify { expect(subject.external_id).to eql(external_id) }
    specify { expect(subject.meta.resource_type).to eql('User') }
    specify { expect(subject.meta.location).to eql(resource_location) }
    specify { expect(subject.meta.created).to eql(created_at) }
    specify { expect(subject.meta.last_modified).to eql(updated_at) }
    specify { expect(subject.meta.version).to eql(version) }

    describe '#as_json' do
      specify { expect(subject.as_json[:id]).to eql(id) }
      specify { expect(subject.as_json[:externalId]).to eql(external_id) }
      specify { expect(subject.as_json[:meta][:resourceType]).to eql('User') }
      specify { expect(subject.as_json[:meta][:location]).to eql(resource_location) }
      specify { expect(subject.as_json[:meta][:created]).to eql(created_at.iso8601) }
      specify { expect(subject.as_json[:meta][:lastModified]).to eql(updated_at.iso8601) }
      specify { expect(subject.as_json[:meta][:version]).to eql(version) }
    end
  end

  context 'with custom string attribute' do
    let(:user_name) { FFaker::Internet.user_name }

    before do
      schema.add_attribute(name: 'userName')
      subject.user_name = user_name
    end

    specify { expect(subject.user_name).to eql(user_name) }
  end
end