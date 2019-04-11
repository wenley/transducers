require './process'
require './transducible'

module Transducers
end

# Ideal usage:

baggage_process = AbstractProcess.new
  flat_mapping { |pallet| pallet.bags }.
  filtering { |bag| bag.non_food? }.
  mapping { |bag|
    if bag.heavy?
      bag.label += " (heavy)"
    end
    bag
  }
(0..9).to_a.transduce(baggage_process, output_class: Array)


