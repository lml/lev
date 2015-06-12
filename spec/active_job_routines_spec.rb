require 'spec_helper'

RSpec.describe 'ActiveJob routines' do
  context 'default configuration' do
    class LaterRoutine
      lev_routine

      protected
      def exec; end
    end

    it 'can perform routines later' do
      LaterRoutine.perform_later
      expect(LaterRoutine).to have_queue_size_of(1)
    end
  end
end
