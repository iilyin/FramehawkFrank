Given /^I send swipes$/ do
    frankly_map( "view:'FHServiceView'", "swipeFromX:y:toX:toY:", "100", "100", "200", "100" )
end
