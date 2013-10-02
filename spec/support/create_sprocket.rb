class CreateSprocket

  lev_routine

protected

  def exec(number, text)
    sprocket = Sprocket.new(integer_gt_2: number, text_only_letters: text)
    sprocket.valid?

    transfer_errors_from(sprocket)
  end

end