class SprocketHandler

  include Lev::Handler

  uses_routine ::CreateSprocket

protected

  def authorized?
    true
  end

  def handle
    fatal_error(code: :no_code, message: 'Code cannot be blank') if params[:code].nil?
    fatal_error(code: :invalid_code) if params[:code] != 'code'
    run(::CreateSprocket, params[:sprocket][:integer_gt_2],
        params[:sprocket][:text_only_letters])
  end

end
