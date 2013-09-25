class Sprocket
  include ActiveAttr::Model

  attribute :integer_gt_2, type: Integer
  validates :integer_gt_2, numericality: { only_integer: true,
                                           greater_than_or_equal_to: 3 }
  attribute :text_only_letters, type: String
  validates :text_only_letters, allow_blank: true,
                                format: { with: /\A[a-zA-Z]+\z/, message: "can only contain letters" }
end