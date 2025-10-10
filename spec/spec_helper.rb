require_relative '../lib/tiq'

RSpec.configure do |config|
    config.color = true
    config.add_formatter :documentation

    # config.filter_run_including focus: true
end
