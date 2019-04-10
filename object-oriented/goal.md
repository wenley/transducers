
# High-level Goal

Want to be able to say:

```ruby
bags_process = Process.
  flat_mapping { |pallet| pallet.bags }.
  rejecting { |bag| bag.smells_like_food? }.
  mapping { |bag| bag.label += " to SFO"; bag }

base_bags = Bag.all
bags_stream = Stream.of(base_bags)
bags_array = base_bags.to_a
bags_observable = Observable.of(base_bags)

output_array = bags_stream.transduce(bags_process, output_class: Array)
output_observable = bags_array.transduce(bags_process, output_class: Observable)
```

```ruby
bags_process =
  flat_mapping { |pallet| pallet.bags } >>
  rejecting { |bag| bag.smells_like_food? } >>
  mapping { |bag| bag.label += " to SFO"; bag }
```

Therefore, need to be able to abstractly create a `bags_process`
