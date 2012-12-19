Then /^I start a "([^\"]*)" session$/ do |session|
  steps %{
      When I touch the menu selection cell marked \"#{session}\"
      Then I wait to see \"preloader_bg.png\"
      Then I wait to not see \"preloader_bg.png\"
      When I touch the button marked \"menu drawer tab\"
      When I wait for 1 seconds
      Then I should see the \"#{session}\" menu selection cell highlighted
  }
end

Then /^I close the "([^\"]*)" session$/ do |session|
  steps %{
    Then I should see the menu selection cell \"#{session}\" close button
    When I touch the menu selection cell \"#{session}\" close button
	  When I wait for the animation
    Then I should see the \"#{session}\" menu selection cell unhighlighted
    Then I should not see the menu selection cell \"#{session}\" close button
  }
end

##########################################
# Open 4 sessions to get alert
##########################################
Then /^I test the four session limits ([\d\.]+) times on three of the following sessions$/ do |iteration, table|
  fails = 0
  
  #Open n number of iterations
  for i in 1..Integer(iteration)
    print "    Test ", i, " of ", iteration, "\n"

    #Randomly select 4 session to open
    randomSet = Set.new
    loop do
      randomSet << table.raw[rand((table.raw).length-1)]
      break if randomSet.size == 4
    end
    randoms = randomSet.to_a()
    for j in 0..3
      retryCount = 1
      
      begin
        #Reset the need for a retry touch
        retryTouch = false

        if j != 3
          step "I start a \"#{randoms[j]}\" session"
            #step "I type \"111\" into the \"imageNameText\" text field"
        else
          steps %{
            When I touch the menu selection cell marked \"#{randoms[j]}\"
            Then I wait to see \"To open this service, please close another active service first.\"
            Then I should see an alert view button marked \"Ok\"
            When I wait for 2 seconds
            When I touch the alert view button marked \"Ok\" at 60,20
            When I wait for 1 seconds
          }
        end
      # If a session failed to open, supress it, and continue
      rescue
        begin
          #Check for Alert View
          steps %{
                  Then I wait to see \"Connection Error\"
                  When I wait for 2 seconds
                  Then I touch the alert view button marked \"Cancel\" at 20,20
                  When I wait for 5 seconds
                }
        rescue
          #Must send the retry to the one rescue level up
          retryTouch = true
        end

        #Retry touching hte button
        if retryTouch == true
          if retryCount < 4
            # print "retry ", retryCount ,"\n"
            retryCount +=1 
            retry 
          end
        end
  
        #Test Failed (too many timeout or alert)
        print "     Failed\n"
        fails+=1;
        break
      end
    end
    
    #Close the opened session
    randoms.each do |session|
      #Attempt to close each session
      begin
        step "I close the \"#{session}\" session"
      rescue
        #Session is not opened
      end
    end
    sleep 1
  end
  
  passed = Integer(iteration) - Integer(fails)
  percentPassed = (Float(passed)/Float(iteration))*100
  print "  ####################################\n"
  printf("  Failed: %d of %s (%.2f%% Passed)\n", fails, iteration, percentPassed)
  print "  ####################################\n"
  if fails != 0
    raise
  end
end

##########################################
# Open 3 sessions multiple times
##########################################
Then /^I open and close ([\d\.]+) iterations of three of the following sessions$/ do |iteration,table|
  fails = 0
  
  #Open n number of iterations
  for i in 1..Integer(iteration)
    print "    Test ", i, " of ", iteration, "\n"

    #Randomly select 3 session to open
    randoms = Set.new
    loop do
      randoms << table.raw[rand((table.raw).length-1)]
      break if randoms.size == 3
    end
    
    #Open the 3 selected session
    randoms.each do |session|
      retryCount = 1
      
      begin
        #Reset the need for a retry touch
        retryTouch = false

        step "I start a \"#{session}\" session"
          #step "I type \"111\" into the \"imageNameText\" text field"
          
        # If a session failed to open, supress it, and continue
      rescue
        begin
          #Check for Alert View
          steps %{
                  Then I wait to see \"Connection Error\"
                  When I wait for 2 seconds
                  Then I touch the alert view button marked \"Cancel\" at 20,20
                  When I wait for 5 seconds
                }
        rescue
          #Must send the retry to the one rescue level up
          retryTouch = true
        end

        #Retry touching hte button
        if retryTouch == true
          if retryCount < 4
            retryCount +=1 
            retry 
          end
        end
  
        #Test Failed (too many timeout or alert)
        print "     Failed\n"
        fails+=1;
        break      
      end
    end
  
    #Close the opened session
    randoms.each do |session|
      #Attempt to close each session
      begin
        step "I close the \"#{session}\" session"
      rescue 
        #Session was not opened
      end
    end
    sleep 1
  end
  
  passed = Integer(iteration) - Integer(fails)
  percentPassed = (Float(passed)/Float(iteration))*100
  print "  ####################################\n"
  printf("  Failed: %d of %s (%.2f%% Passed)\n", fails, iteration, percentPassed)
  print "  ####################################\n"
  if fails != 0
    raise
  end
end
 
