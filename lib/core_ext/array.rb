class Array
  def self.base_process
    Transducers::Process.new(
      init: method(:new),
      step: proc { |array, value| array << value },
    )
  end
end
