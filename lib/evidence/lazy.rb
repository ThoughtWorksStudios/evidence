
module Evidence
  module Lazy
    def compact
      reject(&:nil?)
    end
  end
end
