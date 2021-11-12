# frozen_string_literal: true

namespace :generate do
  desc 'Create migration file'
  task :migration, [:name] do |_, args|
    raise 'Migration name not given' if args[:name].nil?

    require 'dawn'
    template = <<~RUBY
      # frozen_string_literal: true

      Sequel.migration do
        change do
        end
      end
    RUBY
    dest = Dawn.root.join("db/migrations/#{Time.now.to_i}_#{args[:name]}.rb")
    File.write(
      dest,
      template
    )
    puts "#{dest.basename} is generated"
  end
end
