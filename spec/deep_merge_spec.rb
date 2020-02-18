require 'spec_helper'

RSpec.describe Lev::Utilities do

  it "should merge properly" do
    default_options = {
      translations: {
        outputs: {
          scope: :blah
        }
      }
    }

    options = {
      translations: {
        inputs: {
          type: :verbatim
        },
        outputs: {
          map: {foo: :bar}
        }
      }
    }

    expected = {
      translations: {
        outputs: {
          scope: :blah,
          map: {foo: :bar}
        },
        inputs: {
          type: :verbatim
        }
      }
    }

    merged = Lev::Utilities.deep_merge(default_options, options)
    expect(merged).to eq expected
  end

end
