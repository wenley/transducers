
module Transducer
  # Really want Promise semantics for Sidekiq jobs
  # Missing Feature:
  # - Can't return a value from Sidekiq Job!!!
  # - Can't hold pointers to function objects (i.e. Redis vs RAM)
  #
  # Might be able hack in chaining properties to Sidekiq
  #
  # What does Sidekiq actually provide?
  # - Really really good logging!!
  #
  # Where does Ruby fall short?
  # - First-class Functions
  # - True Closures
  #
  # What can we do about it?
  module ParallelSidekiq
    class << self
      # job_params = {
      #   klass: Sidekiq Job Class
      #   params: Parameters
      # }
      def step(sidekiq_batch, job_param)
        batch.jobs do
          job_param[:klass].perform_async(job_param[:params])
        end

        batch
      end

      def transduce(other_step, other_collection, sidekiq_batch)
        # Can't do this because Sidekiq uses Redis instead of memory
        # Can't hold pointers to functions
        temp_klass = Class.new do
          include ParallelSidekiq

          # STEP = other_step
          # INIT_COLLECTION = other_collection
        end

        sidekiq_batch.on(:success, temp_klass, {})
      end
    end

    def on_complete(status, options)
      # Doesn't actually exist
      status.data[:job_return_values].reduce(INIT_COLLECTION) do |coll, value|
        STEP.call(coll, value)
      end

      # This DOES actually exist
      status.data[:fail_info].reduce(INIT_COLLECTION) do |coll, value|
        STEP.call(coll, value)
      end
    end

    def on_success(status, options)
    end
  end

  module Arrays
    class << self
      def step(array, item)
        array + [item]
      end

      def init
        []
      end

      def finish(array)
        array
      end

      def transduce(other_transducible, other_collection, input_array)
        other_collection ||= other_transducible.init

        input_array.reduce(other_collection) do |coll, item|
          other_transducible.step(coll, item)
        end
      end
    end
  end

  module Hashes
    class << self
      def step(hash, item_pair)
        key = item_pair[0]
        value = item_pair[1]
        hash.merge({ key => value })
      end

      def transduce(other_step, other_collection, input_hash)
        input_hash.reduce(other_collection) do |coll, pair|
          other_step(coll, pair)
        end
      end
    end
  end

  module Observable
  end

  def self.mapping(&operation)
    raise ArgumentError, "cannot map without a block" if operation.nil?

    Proc.new do |other_transducible|
      Module.new do
        class << self
          extend other_transducible

          def step(coll, item)
            mapped_value = yield item
            other_transducible.step(coll, mapped_value)
          end
        end
      end
    end
  end

  def self.filtering(&predicate)
    raise ArgumentError, "cannot filter without a block" if predicate.nil?

    Proc.new do |other_transducible|
      Module.new do
        class << self
          extend other_transducible

          def step(coll, item)
            result = yield item
            if result
              other_transducible.step(coll, item)
            else
              coll
            end
          end
        end
      end
    end
  end
end

# Transducer::Array.transduce(
