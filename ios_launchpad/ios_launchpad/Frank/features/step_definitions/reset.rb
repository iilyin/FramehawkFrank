Given /^I reset the application$/ do
  steps "When I quit the simulator"
  SDK    = "6.0"
  APPLICATIONS_DIR = "/Users/#{ENV['USER']}/Library/Application Support/iPhone Simulator/#{SDK}/Applications"
  #APPLICATIONS_DIR = "/Users/iilyin/Library/Application Support/iPhone Simulator/#{SDK}/Applications"
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
  #steps "When I quit the simulator"
  SDK    = "6.0"
  APPLICATIONS_DIR = "/Users/#{ENV['USER']}/Library/Application Support/iPhone Simulator/#{SDK}/Applications"
  #APPLICATIONS_DIR = "/Users/iilyin/Library/Application Support/iPhone Simulator/#{SDK}/Applications"
  USERDEFAULTS_PLIST =
  "Library/Preferences/com.framehawk.ios.Framehawk.frankified.plist"
  Dir.foreach(APPLICATIONS_DIR) do |item|
    next if item == '.' or item == '..'
    if File::exists?(
    "#{APPLICATIONS_DIR}/#{item}/#{USERDEFAULTS_PLIST}")
      %x(/usr/libexec/PlistBuddy -c 'Delete :lastUrl' '#{APPLICATIONS_DIR}/#{item}/Library/Preferences/com.framehawk.ios.Framehawk.frankified.plist')
      %x(/usr/libexec/PlistBuddy -c 'Delete :HasLaunchedOnce' '#{APPLICATIONS_DIR}/#{item}/Library/Preferences/com.framehawk.ios.Framehawk.frankified.plist')
      %x(/usr/libexec/PlistBuddy -c 'Delete :HasAcceptedEULA' '#{APPLICATIONS_DIR}/#{item}/Library/Preferences/com.framehawk.ios.Framehawk.frankified.plist')
      %x(/usr/libexec/PlistBuddy -c 'Delete :defaultProfileId' '#{APPLICATIONS_DIR}/#{item}/Library/Preferences/com.framehawk.ios.Framehawk.frankified.plist')
      %x(/usr/libexec/PlistBuddy -c 'Delete :selectedProfileId' '#{APPLICATIONS_DIR}/#{item}/Library/Preferences/com.framehawk.ios.Framehawk.frankified.plist')
      Dir.foreach("#{APPLICATIONS_DIR}/#{item}/Documents") do |file|
        next if file == '.' or file == '..' or File::directory?("#{APPLICATIONS_DIR}/#{item}/Documents/#{file}")
        FileUtils.rm "#{APPLICATIONS_DIR}/#{item}/Documents/#{file}"
        end
      end
  end
  steps "Given I launch the app"
end