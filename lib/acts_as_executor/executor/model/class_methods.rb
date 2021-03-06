module ActsAsExecutor
  module Executor
    module Model
      module ClassMethods
        def acts_as_executor *arguments
          send :include, ActsAsExecutor::Common::InstanceSupportMethods
          send :include, ActsAsExecutor::Executor::Model::InstanceMethods
          send :include, ActsAsExecutor::Executor::Model::InstanceSupportMethods

          hash = arguments.last.is_a?(Hash) ? arguments.pop : {}
          self.log = hash[:log]

          if ActsAsExecutor.rails_initialized?
            all
            at_exit do
              all.each do |e|
                e.send :shutdown
              end
            end
          end
        end

        def log
          @@log ? @@log : Rails.logger
        end

        def log= log
          @@log = log
        end
      end
    end
  end
end