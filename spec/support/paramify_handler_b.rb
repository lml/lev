class ParamifyHandlerB

  include Lev::Handler

  paramify do 
    attribute :type, type: String
    validates :type, presence: true,
                     inclusion: { in: %w(Name Username Any),
                                  message: "is not valid" }

    attribute :value, type: Integer
  end

protected

  def authorized?; true; end

  def handle
    outputs[:success] = true if paramify_params.value == 2
  end

end
