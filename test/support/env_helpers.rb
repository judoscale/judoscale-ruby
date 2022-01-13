# frozen_string_literal: true

module EnvHelpers
  attr_accessor :_original_env

  # Overrides ENV values for the duration of the block.
  # Example:
  #   use_env "RAILS_ENV" => "production" do
  #     ...
  #   end
  def use_env(config, &test)
    setup_env(config)
    test.call
  ensure
    restore_env
  end

  # Overrides ENV values during the test setup, use `restore_env` to revert to original values.
  # Example:
  #   setup_env "RAILS_ENV" => "production"
  #   ... test stuff
  #   restore_env
  #
  # Example with before/after hooks:
  #   before { setup_env ... }
  #   after { restore_env }
  def setup_env(config)
    self._original_env = {}

    config.each do |key, val|
      _original_env[key] = ENV[key]
      ENV[key] = val
    end

    # Force config to load with the swapped ENV.
    Singleton.__init__(Judoscale::Config)
    Judoscale::Config.instance
  end

  # Restores ENV values to their original state. (from when `setup_env` was called, see it for more info.)
  def restore_env
    return unless _original_env

    _original_env.each do |key, val|
      ENV[key] = val
    end
  end

  # Always restore ENV on teardown for each test to ensure changes don't leak to other tests.
  def after_teardown
    restore_env
    super
  end
end

Judoscale::Test.include EnvHelpers
