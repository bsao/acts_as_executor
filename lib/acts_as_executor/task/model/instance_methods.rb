module ActsAsExecutor
  module Task
    module Model
      module InstanceMethods
        def self.included base
          # Associations
          base.belongs_to :executor, :class_name => base.table_name.sub(/_tasks/, "").camelize

          # Callbacks
          base.after_find :enqueue, :if => :enqueueable?
          base.after_save :enqueue, :if => :enqueueable?
          base.after_destroy :cancel, :if => :cancelable?

          # Serialization
          base.serialize :arguments, Hash

          # Validations
          base.validates :executor_id, :presence => true
          base.validates :executable, :presence => true, :class_exists => true, :class_subclasses => { :superclass => ActsAsExecutor::Task::Executable }
          base.validates :schedule, :inclusion => { :in => ActsAsExecutor::Task::Schedules::ALL }, :if => "executor and executor.schedulable?"
          base.validates :started, :numericality => { :only_integer => true, :greater_than_or_equal_to => 0 }, :if => "executor and executor.schedulable?"
          base.validates :every, :numericality => { :only_integer => true, :greater_than_or_equal_to => 1 }, :if => "executor and executor.schedulable? and schedule != ActsAsExecutor::Task::Schedules::ONE_SHOT"
          base.validates :units, :inclusion => { :in => ActsAsExecutor::Common::Units::ALL }, :if => "executor and executor.schedulable?"
        end

        private
        def enqueue
          begin
            executor.send(:log).debug log_message executor.name, "creating", id.to_s, executable, arguments

            instance = instantiate executable, arguments

            self.future = executor.send(:execute, instance, id.to_s, schedule, start, every, units)
            future.done_handler = method :done_handler unless executor.send(:schedulable?)
          rescue RuntimeError => exception
            executor.send(:log).error log_message executor.name, "creating", id.to_s, executable, "encountered an unexpected exception. " + exception.to_s
          end
        end

        def instantiate class_name, arguments
          instance = Object.const_get(class_name).new
          instance.arguments = arguments
          instance.uncaught_exception_handler = method :uncaught_exception_handler
          instance
        end

        def done_handler
          executor.send(:log).debug log_message executor.name, "completed", id.to_s, executable
          destroy
        end

        def uncaught_exception_handler exception
          executor.send(:log).error log_message executor.name, "executing", id.to_s, executable, "encountered an uncaught exception. " + exception.to_s
        end

        def cancel
          future.cancel true

          self.future = nil
        end
      end
    end
  end
end