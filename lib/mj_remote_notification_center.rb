unless defined?(Motion::Project::Config)
  raise "This file must be required within a RubyMotion project Rakefile."
end

Motion::Project::App.setup do |app|
  app.frameworks << "GameKit"

  Dir.glob(File.join(File.dirname(__FILE__), 'mj_remote_notification_center/*.rb')).each do |file|
    puts "LOADING FILE >> #{ file }"
    app.files.unshift(file)
  end
end
