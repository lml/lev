require_relative './delegated_routine'

class DelegatingRoutine
  lev_routine delegates_to: DelegatedRoutine
end
