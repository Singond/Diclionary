require "./cli"

# Setup logging
Log.define_formatter Fmt, "#{source}: #{message}"
# Use 'Sync' dispatch mode to ensure correct interleaving with output
log_backend = Log::IOBackend.new(io: STDERR, formatter: Fmt, dispatcher: :sync)
Log.setup("*", :warn, log_backend)

# Run with CLI arguments
code = Diclionary::Cli.run
exit code.value
