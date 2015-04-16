class DelegatedRoutine
  lev_routine express_output: :answer

  protected

  def exec(alpha, beta)
    outputs[:answer] = alpha + beta
  end

end
