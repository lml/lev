class TestValidity < ActiveRecord::Base
  validates :required_field, presence: true
end
