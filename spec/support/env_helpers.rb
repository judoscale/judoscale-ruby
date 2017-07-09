module EnvHelpers
  # Override ENV config for a single spec
  # Example:
  #   around { |example| use_env({'RAILS_ENV' => 'production'}, &example) }
  def use_env(config, &example)
    original_env = {}

    config.each do |key, val|
      original_env[key] = ENV[key]
      ENV[key] = val
    end

    example.call

    config.each do |key, val|
      ENV[key] = original_env[key]
    end
  end
end

RSpec.configure do |c|
  c.include EnvHelpers
end
