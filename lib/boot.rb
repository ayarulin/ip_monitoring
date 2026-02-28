require 'zeitwerk'

loader = Zeitwerk::Loader.new
loader.push_dir(File.expand_path(__dir__))
loader.ignore(File.expand_path('infrastructure/db/migrations', __dir__))
loader.setup
