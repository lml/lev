class CreateSprocket

  include Lev::Routine

protected

  def exec(number, text)
    sprocket = Sprocket.new(integer_gt_2: number, text_only_letters: text)
    sprocket.valid?

    transfer_errors_from(sprocket, {scope: :sprocket})
  end

end
