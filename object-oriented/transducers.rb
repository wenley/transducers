require './process'
require './transducible'

module Transducers
  ReducedValue = Struct.new(:value)
end

# Ideal usage:

baggage_process = Transducers.base_process.
  flat_mapping { |pallet| pallet.bags }.
  filtering { |bag| bag.non_food? }.
  mapping { |bag|
    if bag.heavy?
      bag.label += " (heavy)"
    end
    bag
  }
(0..9).to_a.transduce(
