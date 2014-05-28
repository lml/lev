class ParamifyHandlerA

  include Lev::Handler

  paramify :terms do 
    attribute :type, type: String
    validates :type, presence: true,
                            inclusion: { in: %w(Name Username Any),
                                         message: "is not valid" }
  end

protected

  def authorized?; true; end
  def handle; end

end
