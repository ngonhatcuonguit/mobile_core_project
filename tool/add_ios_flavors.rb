#!/usr/bin/env ruby
# Script to add Flutter flavor build configurations to Xcode project
# This creates Debug-dev, Release-dev, Profile-dev, Debug-prod, Release-prod, Profile-prod

require 'xcodeproj'

project_path = File.join(__dir__, '..', 'ios', 'Runner.xcodeproj')
project = Xcodeproj::Project.open(project_path)

flavors = ['dev', 'prod']
base_configs = {
  'Debug' => :debug,
  'Release' => :release,
  'Profile' => :release
}

# Check if flavor configs already exist
existing_names = project.build_configurations.map(&:name)
if existing_names.any? { |n| n.include?('-dev') || n.include?('-prod') }
  puts "Flavor configurations already exist. Skipping."
  exit 0
end

flavors.each do |flavor|
  base_configs.each do |base_name, type|
    config_name = "#{base_name}-#{flavor}"
    puts "Creating: #{config_name}"

    # Add to project
    project_base = project.build_configurations.find { |c| c.name == base_name }
    project_config = project.add_build_configuration(config_name, type)
    project_config.build_settings = project_base.build_settings.clone

    # Add to each target
    project.targets.each do |target|
      target_base = target.build_configurations.find { |c| c.name == base_name }
      target_config = target.add_build_configuration(config_name, type)
      target_config.build_settings = target_base.build_settings.clone
    end
  end
end

project.save
puts "\n✅ Added flavor build configurations successfully!"
puts "   Configurations: #{project.build_configurations.map(&:name).join(', ')}"

