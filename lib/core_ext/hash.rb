class Hash
  # If collecting into
  def self.base_process
    Transducers::Process.new(
      init: method(:new),
      step: proc { |hash, (key, value)| hash[key] = value; hash },
    )
  end
end
