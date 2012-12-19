Given /^I reset the application$/ do
  steps "When I quit the simulator"
  SDK    = "6.0"
  APPLICATIONS_DIR = "/Users/#{ENV['USER']}/Library/Application Support/iPhone Simulator/#{SDK}/Applications"
  USERDEFAULTS_PLIST =
  "Library/Preferences/com.framehawk.ios.Framehawk.frankified.plist"
  Dir.foreach(APPLICATIONS_DIR) do |item|
    next if item == '.' or item == '..'
    if File::exists?(
    "#{APPLICATIONS_DIR}/#{item}/#{USERDEFAULTS_PLIST}")
      FileUtils.rm "#{APPLICATIONS_DIR}/#{item}/#{USERDEFAULTS_PLIST}"
    end
  end
  steps "Given I launch the app"
end

Given /^I reset the application and profiles$/ do
    steps "When I quit the simulator"
    SDK    = "6.0"
    APPLICATIONS_DIR = "/Users/#{ENV['USER']}/Library/Application Support/iPhone Simulator/#{SDK}/Applications"
    USERDEFAULTS_PLIST =
    "Library/Preferences/com.framehawk.ios.Framehawk.frankified.plist"
    Dir.foreach(APPLICATIONS_DIR) do |item|
        next if item == '.' or item == '..'
        if File::exists?(
                         "#{APPLICATIONS_DIR}/#{item}/#{USERDEFAULTS_PLIST}")
            FileUtils.rm "#{APPLICATIONS_DIR}/#{item}/#{USERDEFAULTS_PLIST}"
            Dir.foreach("#{APPLICATIONS_DIR}/#{item}/Documents") do |file|
                next if file == '.' or file == '..' or File::directory?("#{APPLICATIONS_DIR}/#{item}/Documents/#{file}")
                FileUtils.rm "#{APPLICATIONS_DIR}/#{item}/Documents/#{file}"
            end
        end
    end
    steps "Given I launch the app"
end