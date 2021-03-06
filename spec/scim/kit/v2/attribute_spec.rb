# frozen_string_literal: true

RSpec.describe Scim::Kit::V2::Attribute do
  subject { described_class.new(type: type, resource: resource) }

  let(:resource) { Scim::Kit::V2::Resource.new(schemas: [schema], location: FFaker::Internet.uri('https')) }
  let(:schema) { Scim::Kit::V2::Schema.new(id: Scim::Kit::V2::Schemas::USER, name: 'User', location: FFaker::Internet.uri('https')) }

  context 'with strings' do
    let(:type) { Scim::Kit::V2::AttributeType.new(name: 'userName', type: :string) }

    context 'when valid' do
      let(:user_name) { FFaker::Internet.user_name }

      before { subject._value = user_name }

      specify { expect(subject._value).to eql(user_name) }
      specify { expect(subject.as_json[:userName]).to eql(user_name) }
      specify { expect(subject).to be_valid }
    end

    context 'when multiple values are allowed' do
      before { type.multi_valued = true }

      specify { expect(subject._value).to match_array([]) }

      context 'when multiple valid values are added' do
        before do
          subject._value = %w[superman batman]
        end

        specify { expect(subject._value).to match_array(%w[superman batman]) }
        specify { expect(subject).to be_valid }
      end

      context 'when multiple invalid values are added' do
        before do
          subject._assign(['superman', {}], coerce: false)
        end

        specify { expect(subject).not_to be_valid }
      end
    end

    context 'when a single value is provided' do
      before do
        type.multi_valued = true
        subject._value = 'batman'
        subject.valid?
      end

      specify { expect(subject).not_to be_valid }
      specify { expect(subject.errors[:user_name]).to be_present }
    end

    context 'when the wrong type is used' do
      before do
        type.multi_valued = true
        subject._assign([1.0, 2.0], coerce: false)
        subject.valid?
      end

      specify { expect(subject).not_to be_valid }
      specify { expect(subject.errors[:user_name]).to be_present }
    end

    context 'when integer' do
      let(:number) { rand(100) }

      before { subject._value = number }

      specify { expect(subject._value).to eql(number.to_s) }
    end

    context 'when datetime' do
      let(:datetime) { DateTime.now }

      before { subject._value = datetime }

      specify { expect(subject._value).to eql(datetime.to_s) }
    end

    context 'when not matching a canonical value' do
      before do
        type.canonical_values = %w[batman robin]
        subject._value = 'spider man'
        subject.valid?
      end

      specify { expect(subject).not_to be_valid }
      specify { expect(subject.errors[:user_name]).to be_present }
    end

    context 'when canonical value is given' do
      before do
        type.canonical_values = %w[batman robin]
        subject._value = 'batman'
      end

      specify { expect(subject._value).to eql('batman') }
    end
  end

  context 'with boolean' do
    let(:type) { Scim::Kit::V2::AttributeType.new(name: 'hungry', type: :boolean) }

    context 'when true' do
      before { subject._value = true }

      specify { expect(subject._value).to be(true) }
      specify { expect(subject.as_json[:hungry]).to be(true) }
    end

    context 'when false' do
      before { subject._value = false }

      specify { expect(subject._value).to be(false) }
      specify { expect(subject.as_json[:hungry]).to be(false) }
    end

    context 'when invalid string' do
      before { subject._value = 'hello' }

      specify { expect(subject._value).to eql('hello') }
      specify { expect(subject).not_to be_valid }
    end
  end

  context 'with decimal' do
    let(:type) { Scim::Kit::V2::AttributeType.new(name: 'measurement', type: :decimal) }

    context 'when given float' do
      before { subject._value = Math::PI }

      specify { expect(subject._value).to eql(Math::PI) }
      specify { expect(subject.as_json[:measurement]).to be(Math::PI) }
    end

    context 'when given an integer' do
      before { subject._value = 42 }

      specify { expect(subject._value).to eql(42.to_f) }
      specify { expect(subject.as_json[:measurement]).to be(42.to_f) }
    end
  end

  context 'with integer' do
    let(:type) { Scim::Kit::V2::AttributeType.new(name: 'age', type: :integer) }

    context 'when given integer' do
      before { subject._value = 34 }

      specify { expect(subject._value).to be(34) }
      specify { expect(subject.as_json[:age]).to be(34) }
    end

    context 'when given float' do
      before { subject._value = Math::PI }

      specify { expect(subject._value).to eql(Math::PI.to_i) }
    end
  end

  context 'with datetime' do
    let(:type) { Scim::Kit::V2::AttributeType.new(name: 'birthdate', type: :datetime) }
    let(:datetime) { DateTime.new(2019, 0o1, 0o6, 12, 35, 0o0) }

    context 'when given a date time' do
      before { subject._value = datetime }

      specify { expect(subject._value).to eql(datetime) }
      specify { expect(subject.as_json[:birthdate]).to eql(datetime.iso8601) }
    end

    context 'when given a string' do
      before { subject._value = datetime.to_s }

      specify { expect(subject._value).to eql(datetime) }
    end
  end

  context 'with binary' do
    let(:type) { Scim::Kit::V2::AttributeType.new(name: 'photo', type: :binary) }
    let(:photo) { IO.read('./spec/fixtures/avatar.png', mode: 'rb') }

    context 'when given a .png' do
      before { subject._value = photo }

      specify { expect(subject._value).to eql(Base64.strict_encode64(photo)) }
      specify { expect(subject.as_json[:photo]).to eql(Base64.strict_encode64(photo)) }
    end
  end

  context 'with reference' do
    let(:type) { Scim::Kit::V2::AttributeType.new(name: 'group', type: :reference) }
    let(:uri) { FFaker::Internet.uri('https') }

    before { subject._value = uri }

    specify { expect(subject._value).to eql(uri) }
    specify { expect(subject.as_json[:group]).to eql(uri) }
  end

  context 'with complex type' do
    let(:type) do
      x = Scim::Kit::V2::AttributeType.new(name: 'name', type: :complex)
      x.add_attribute(name: 'familyName')
      x.add_attribute(name: 'givenName')
      x
    end

    before do
      subject.family_name = 'Garrett'
      subject.given_name = 'Tsuyoshi'
    end

    specify { expect(subject.family_name).to eql('Garrett') }
    specify { expect(subject.given_name).to eql('Tsuyoshi') }
    specify { expect(subject.as_json[:name][:familyName]).to eql('Garrett') }
    specify { expect(subject.as_json[:name][:givenName]).to eql('Tsuyoshi') }
  end

  context 'with single valued complex type' do
    let(:type) do
      x = Scim::Kit::V2::AttributeType.new(name: :person, type: :complex)
      x.add_attribute(name: :name)
      x.add_attribute(name: :age, type: :integer)
      x
    end

    specify do
      subject.name = 'mo'
      subject.age = 34
      expect(subject).to be_valid
    end

    specify do
      subject.name = 'mo'
      subject.age = []
      expect(subject).not_to be_valid
    end
  end

  context 'with multi valued complex type' do
    let(:type) do
      x = Scim::Kit::V2::AttributeType.new(name: 'emails', type: :complex)
      x.multi_valued = true
      x.add_attribute(name: 'value') do |y|
        y.required = true
      end
      x.add_attribute(name: 'primary', type: :boolean)
      x
    end
    let(:email) { FFaker::Internet.email }
    let(:other_email) { FFaker::Internet.email }

    before do
      subject._value = [
        { value: email, primary: true },
        { value: other_email, primary: false }
      ]
    end

    specify { expect(subject._value).to match_array([{ value: email, primary: true }, { value: other_email, primary: false }]) }
    specify { expect(subject.as_json[:emails]).to match_array([{ value: email, primary: true }, { value: other_email, primary: false }]) }
    specify { expect(subject).to be_valid }

    context 'when the hash is invalid' do
      before do
        subject._value = [{ blah: 'blah' }]
        subject.valid?
      end

      specify { expect(subject).not_to be_valid }
      specify { expect(subject.errors[:blah]).to be_present }
      specify { expect(subject.errors[:value]).to be_present }
    end
  end

  context 'when the resource is in server mode' do
    let(:type) { Scim::Kit::V2::AttributeType.new(name: 'userName', type: :string) }
    let(:resource) { instance_double(Scim::Kit::V2::Resource) }

    before do
      allow(resource).to receive(:mode?).with(:server).and_return(true)
      allow(resource).to receive(:mode?).with(:client).and_return(false)
    end

    context 'when the type is read only' do
      before { type.mutability = :read_only }

      specify { expect(subject).to be_renderable }
    end

    context 'when the type is write only' do
      before { type.mutability = :write_only }

      specify { expect(subject).not_to be_renderable }
    end

    context 'when returned type is `never`' do
      before { type.returned = :never }

      specify { expect(subject).not_to be_renderable }
    end
  end

  context 'when the resource is in client mode' do
    let(:type) { Scim::Kit::V2::AttributeType.new(name: 'userName', type: :string) }
    let(:resource) { instance_double(Scim::Kit::V2::Resource) }

    before do
      allow(resource).to receive(:mode?).with(:server).and_return(false)
      allow(resource).to receive(:mode?).with(:client).and_return(true)
    end

    context 'when the type is read only' do
      before { type.mutability = :read_only }

      specify { expect(subject).not_to be_renderable }
    end

    context 'when the type is write only' do
      before { type.mutability = :write_only }

      specify do
        subject._value = 'hello'
        expect(subject).to be_renderable
      end

      specify do
        subject._value = nil
        expect(subject).not_to be_renderable
      end
    end
  end
end
