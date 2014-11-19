require "capybara/workflows/version"

module Capybara
  module Workflows
    # for use in capybara integration tests
    # session : the test session, where capybara and other libraries/helpers are available
    class WorkflowSet < Struct.new(:session)
      def self.workflow(name, &block)
        workflow = Proc.new do |*args| session.instance_exec(*[*args, self], &block) end
        define_method(name, &workflow)
      end
    end
  end
end
