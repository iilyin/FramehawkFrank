def send_command ( command )
    %x{osascript<<APPLESCRIPT
        tell application "System Events"
        tell application "iPhone Simulator" to activate
        keystroke "#{command}"
        end tell
    APPLESCRIPT}
end

def send_tab ()
    %x{osascript<<APPLESCRIPT
        tell application "System Events"
        tell application "iPhone Simulator" to activate
        key code 48
        end tell
    APPLESCRIPT}
end

def send_return ()
    %x{osascript<<APPLESCRIPT
        tell application "System Events"
        tell application "iPhone Simulator" to activate
        key code 36
        end tell
    APPLESCRIPT}
end

Then /^I save a screenshot with prefix (\w+)$/ do |prefix|
    filename = prefix + Time.now.to_i.to_s
    %x[screencapture #{filename}.png]
end

When /^I send the command "([^\\"]*)"$/ do |cmd|
    send_command(cmd)
end

When /^I send tab key$/ do
    send_tab()
end

When /^I send return key$/ do
    send_return()
end

Then /^I log in to google drive$/ do
    touch "view:'UIView' marked:'KeyboardButton'"
    step "I wait for 3 seconds"
    step "I send the command \"framehawktestuser\""
    step "I send tab key"
    step "I send the command \"framehawk123\""
    step "I send return key"
end

When /^I open template url$/ do
    frankly_map( "view:'ImageTestView'", "simulateF6" )
    step "I send the command \"https://drive.google.com/templates?q=FHTest1&sort=hottest&view=public\""
    step "I send return key"
    step "I wait for 2 seconds"
    frankly_map( "view:'ImageTestView'", "toggleKeyboard" )
    step "I wait for 1 seconds"
    frankly_map( "view:'FHServiceView'", "touchx:y:", "425", "406" )
    
    step "I wait for 15 seconds"
end

Then /^I type abcde$/ do
    touch "view:'UIView' marked:'KeyboardButton'"

    %w{a b c d e f g h i j k l}.each{|char|
        step "I send the command \"#{char}\""
        step "I wait for 0.5 seconds"
        frankly_map( "view:'ImageTestView'", "sendRight" )
        step "I wait for 0.5 seconds"
    }
    
    frankly_map( "view:'ImageTestView'", "sendLeft" )
    frankly_map( "view:'ImageTestView'", "sendDown" )
    step "I wait for 0.5 seconds"

    %w{x w v u t s r q p o n m}.each{|char|
        step "I send the command \"#{char}\""
        step "I wait for 0.5 seconds"
        frankly_map( "view:'ImageTestView'", "sendLeft" )
        step "I wait for 0.5 seconds"
    }
    
    frankly_map( "view:'ImageTestView'", "sendDown" )
    step "I wait for 0.5 seconds"

    %w{y z 1 2 3 4 5 6 7 8 9 0}.each{|char|
        step "I send the command \"#{char}\""
        step "I wait for 0.5 seconds"
        frankly_map( "view:'ImageTestView'", "sendRight" )
        step "I wait for 0.5 seconds"
    }
    
    frankly_map( "view:'ImageTestView'", "sendLeft" )
    frankly_map( "view:'ImageTestView'", "sendDown" )

    %w{L K J I H G F E D C B A}.each{|char|
        step "I send the command \"#{char}\""
        step "I wait for 0.5 seconds"
        frankly_map( "view:'ImageTestView'", "sendLeft" )
        step "I wait for 0.5 seconds"
    }
    
    frankly_map( "view:'ImageTestView'", "sendDown" )
    step "I wait for 0.5 seconds"
    
    %w{M N O P Q R S T U V W X}.each{|char|
        step "I send the command \"#{char}\""
        step "I wait for 0.5 seconds"
        frankly_map( "view:'ImageTestView'", "sendRight" )
        step "I wait for 0.5 seconds"
    }
    
    frankly_map( "view:'ImageTestView'", "sendLeft" )
    frankly_map( "view:'ImageTestView'", "sendDown" )
    
    %w{. @ & $ ) ( ; : / - Z Y}.each{|char|
        step "I send the command \"#{char}\""
        step "I wait for 0.5 seconds"
        frankly_map( "view:'ImageTestView'", "sendLeft" )
        step "I wait for 0.5 seconds"
    }
    
    frankly_map( "view:'ImageTestView'", "sendDown" )
    step "I wait for 0.5 seconds"
    
    %w{, ? ! .'}.each{|char|
        step "I send the command \"#{char}\""
        step "I wait for 0.5 seconds"
        frankly_map( "view:'ImageTestView'", "sendRight" )
        step "I wait for 0.5 seconds"
    }

    %x{osascript<<APPLESCRIPT
        tell application "System Events"
        tell application "iPhone Simulator" to activate
        key down shift
        key code 39
        key up shift
        end tell
        APPLESCRIPT}
    step "I wait for 0.5 seconds"
    frankly_map( "view:'ImageTestView'", "sendRight" )
    step "I wait for 0.5 seconds"
                  
                  
    %w{[ ] \{ \}}.each{|char|
        step "I send the command \"#{char}\""
        step "I wait for 0.5 seconds"
        frankly_map( "view:'ImageTestView'", "sendRight" )
        step "I wait for 0.5 seconds"
    }

    %x{osascript<<APPLESCRIPT
        tell application "System Events"
        tell application "iPhone Simulator" to activate
        key down shift
        key code 20
        key up shift
        end tell
        APPLESCRIPT}
    step "I wait for 0.5 seconds"
    frankly_map( "view:'ImageTestView'", "sendRight" )
    step "I wait for 0.5 seconds"

    %w{% ^}.each{|char|
        step "I send the command \"#{char}\""
        step "I wait for 0.5 seconds"
        frankly_map( "view:'ImageTestView'", "sendRight" )
        step "I wait for 0.5 seconds"
    }

    frankly_map( "view:'ImageTestView'", "sendLeft" )
                  step "I wait for 0.5 seconds"
    frankly_map( "view:'ImageTestView'", "sendLeft" )
                  step "I wait for 0.5 seconds"
    frankly_map( "view:'ImageTestView'", "sendLeft" )
                  step "I wait for 0.5 seconds"
    frankly_map( "view:'ImageTestView'", "sendLeft" )
                  step "I wait for 0.5 seconds"
    frankly_map( "view:'ImageTestView'", "sendDown" )
                  
    %w{> < ~ |}.each{|char|
        step "I send the command \"#{char}\""
        step "I wait for 0.5 seconds"
        frankly_map( "view:'ImageTestView'", "sendLeft" )
        step "I wait for 0.5 seconds"
    }

                  %x{osascript<<APPLESCRIPT
                  tell application "System Events"
                  tell application "iPhone Simulator" to activate
                  key code 42
                  end tell
                  APPLESCRIPT}
                  step "I wait for 0.5 seconds"
                  frankly_map( "view:'ImageTestView'", "sendLeft" )
                  step "I wait for 0.5 seconds"

                  %w{_ '= '+ *}.each{|char|
                  step "I send the command \"#{char}\""
                  step "I wait for 0.5 seconds"
                  frankly_map( "view:'ImageTestView'", "sendLeft" )
                  step "I wait for 0.5 seconds"
                  }
                  
    frankly_map( "view:'ImageTestView'", "toggleKeyboard" )
    step "I wait for 3 seconds"
end
                  
def check_image(shotImage, checkImage, x, y, outFile, testName)
    %x(./imageChecker #{shotImage} #{checkImage} #{x} #{y})
    res = $?.exitstatus
    puts "exit status = #{res}"
    if res == 0
        outFile.write(" <tr><td>")
        outFile.write("#{testName}")
        outFile.write("</td><td style='color:green'>PASSED</td></tr>\n")
    else
        outFile.write(" <tr><td>")
        outFile.write("#{testName}")
        outFile.write("</td><td style='color:red'>FAILED</td></tr>\n")
    end
end
                  

Then /^I check color of the cell$/ do

    `./simulatorExtractor`
    File.open("/Users/Shared/report.html", "w") {|f|
        f.write("<html><body><table border=\"2px\"><tbody>\n")
        
        check_image("/Users/Shared/test.png", "/Users/Shared/1.png", 90, 263, f, "Test 01: 'a' input")
        check_image("/Users/Shared/test.png", "/Users/Shared/1.png", 161, 263, f, "Test 02: 'b' input" )
        check_image("/Users/Shared/test.png", "/Users/Shared/1.png", 232, 263, f, "Test 03: 'c' input" )
        check_image("/Users/Shared/test.png", "/Users/Shared/1.png", 304, 263, f, "Test 04: 'd' input" )
        check_image("/Users/Shared/test.png", "/Users/Shared/1.png", 375, 263, f, "Test 05: 'e' input" )
        check_image("/Users/Shared/test.png", "/Users/Shared/1.png", 446, 263, f, "Test 06: 'f' input" )
        check_image("/Users/Shared/test.png", "/Users/Shared/1.png", 517, 263, f, "Test 07: 'j' input" )
        check_image("/Users/Shared/test.png", "/Users/Shared/1.png", 588, 263, f, "Test 08: 'h' input" )
        check_image("/Users/Shared/test.png", "/Users/Shared/1.png", 659, 263, f, "Test 09: 'i' input" )
        check_image("/Users/Shared/test.png", "/Users/Shared/1.png", 730, 263, f, "Test 10: 'j' input" )
        check_image("/Users/Shared/test.png", "/Users/Shared/1.png", 801, 263, f, "Test 11: 'k' input" )
        check_image("/Users/Shared/test.png", "/Users/Shared/1.png", 872, 263, f, "Test 12: 'l' input" )

        check_image("/Users/Shared/test.png", "/Users/Shared/1.png", 90, 281, f, "Test 13: 'm' input" )
        check_image("/Users/Shared/test.png", "/Users/Shared/1.png", 161, 281, f, "Test 14: 'n' input" )
        check_image("/Users/Shared/test.png", "/Users/Shared/1.png", 232, 281, f, "Test 15: 'o' input" )
        check_image("/Users/Shared/test.png", "/Users/Shared/1.png", 304, 281, f, "Test 16: 'p' input" )
        check_image("/Users/Shared/test.png", "/Users/Shared/1.png", 375, 281, f, "Test 17: 'q' input" )
        check_image("/Users/Shared/test.png", "/Users/Shared/1.png", 446, 281, f, "Test 18: 'r' input" )
        check_image("/Users/Shared/test.png", "/Users/Shared/1.png", 517, 281, f, "Test 19: 's' input" )
        check_image("/Users/Shared/test.png", "/Users/Shared/1.png", 588, 281, f, "Test 20: 't' input" )
        check_image("/Users/Shared/test.png", "/Users/Shared/1.png", 659, 281, f, "Test 21: 'u' input" )
        check_image("/Users/Shared/test.png", "/Users/Shared/1.png", 730, 281, f, "Test 22: 'v' input" )
        check_image("/Users/Shared/test.png", "/Users/Shared/1.png", 801, 281, f, "Test 23: 'w' input" )
        check_image("/Users/Shared/test.png", "/Users/Shared/1.png", 872, 281, f, "Test 24: 'x' input" )
                  
        check_image("/Users/Shared/test.png", "/Users/Shared/1.png", 90, 299, f, "Test 25: 'y' input" )
        check_image("/Users/Shared/test.png", "/Users/Shared/1.png", 161, 299, f, "Test 26: 'z' input" )
        check_image("/Users/Shared/test.png", "/Users/Shared/1.png", 232, 299, f, "Test 27: '1' input" )
        check_image("/Users/Shared/test.png", "/Users/Shared/1.png", 304, 299, f, "Test 28: '2' input" )
        check_image("/Users/Shared/test.png", "/Users/Shared/1.png", 375, 299, f, "Test 29: '3' input" )
        check_image("/Users/Shared/test.png", "/Users/Shared/1.png", 446, 299, f, "Test 30: '4' input" )
        check_image("/Users/Shared/test.png", "/Users/Shared/1.png", 517, 299, f, "Test 31: '5' input" )
        check_image("/Users/Shared/test.png", "/Users/Shared/1.png", 588, 299, f, "Test 32: '6' input" )
        check_image("/Users/Shared/test.png", "/Users/Shared/1.png", 659, 299, f, "Test 33: '7' input" )
        check_image("/Users/Shared/test.png", "/Users/Shared/1.png", 730, 299, f, "Test 34: '8' input" )
        check_image("/Users/Shared/test.png", "/Users/Shared/1.png", 801, 299, f, "Test 35: '9' input" )
        check_image("/Users/Shared/test.png", "/Users/Shared/1.png", 872, 299, f, "Test 36: '0' input" )
                  
        check_image("/Users/Shared/test.png", "/Users/Shared/1.png", 90, 317, f, "Test 37: 'A' input" )
        check_image("/Users/Shared/test.png", "/Users/Shared/1.png", 161, 317, f, "Test 38: 'B' input" )
        check_image("/Users/Shared/test.png", "/Users/Shared/1.png", 232, 317, f, "Test 39: 'C' input" )
        check_image("/Users/Shared/test.png", "/Users/Shared/1.png", 304, 317, f, "Test 40: 'D' input" )
        check_image("/Users/Shared/test.png", "/Users/Shared/1.png", 375, 317, f, "Test 41: 'E' input" )
        check_image("/Users/Shared/test.png", "/Users/Shared/1.png", 446, 317, f, "Test 42: 'F' input" )
        check_image("/Users/Shared/test.png", "/Users/Shared/1.png", 517, 317, f, "Test 43: 'G' input" )
        check_image("/Users/Shared/test.png", "/Users/Shared/1.png", 588, 317, f, "Test 44: 'H' input" )
        check_image("/Users/Shared/test.png", "/Users/Shared/1.png", 659, 317, f, "Test 45: 'I' input" )
        check_image("/Users/Shared/test.png", "/Users/Shared/1.png", 730, 317, f, "Test 46: 'J' input" )
        check_image("/Users/Shared/test.png", "/Users/Shared/1.png", 801, 317, f, "Test 47: 'K' input" )
        check_image("/Users/Shared/test.png", "/Users/Shared/1.png", 872, 317, f, "Test 48: 'L' input" )
                  
        check_image("/Users/Shared/test.png", "/Users/Shared/1.png", 90, 335, f, "Test 49: 'M' input" )
        check_image("/Users/Shared/test.png", "/Users/Shared/1.png", 161, 335, f, "Test 50: 'N' input" )
        check_image("/Users/Shared/test.png", "/Users/Shared/1.png", 232, 335, f, "Test 51: 'O' input" )
        check_image("/Users/Shared/test.png", "/Users/Shared/1.png", 304, 335, f, "Test 52: 'P' input" )
        check_image("/Users/Shared/test.png", "/Users/Shared/1.png", 375, 335, f, "Test 53: 'Q' input" )
        check_image("/Users/Shared/test.png", "/Users/Shared/1.png", 446, 335, f, "Test 54: 'R' input" )
        check_image("/Users/Shared/test.png", "/Users/Shared/1.png", 517, 335, f, "Test 55: 'S' input" )
        check_image("/Users/Shared/test.png", "/Users/Shared/1.png", 588, 335, f, "Test 56: 'T' input" )
        check_image("/Users/Shared/test.png", "/Users/Shared/1.png", 659, 335, f, "Test 57: 'U' input" )
        check_image("/Users/Shared/test.png", "/Users/Shared/1.png", 730, 335, f, "Test 58: 'V' input" )
        check_image("/Users/Shared/test.png", "/Users/Shared/1.png", 801, 335, f, "Test 59: 'W' input" )
        check_image("/Users/Shared/test.png", "/Users/Shared/1.png", 872, 335, f, "Test 60: 'X' input" )
                
        check_image("/Users/Shared/test.png", "/Users/Shared/1.png", 90, 353, f, "Test 61: 'Y' input" )
        check_image("/Users/Shared/test.png", "/Users/Shared/1.png", 161, 353, f, "Test 62: 'Z' input" )
        check_image("/Users/Shared/test.png", "/Users/Shared/1.png", 232, 353, f, "Test 63: '-' input" )
        check_image("/Users/Shared/test.png", "/Users/Shared/1.png", 304, 353, f, "Test 64: '/' input" )
        check_image("/Users/Shared/test.png", "/Users/Shared/1.png", 375, 353, f, "Test 65: ':' input" )
        check_image("/Users/Shared/test.png", "/Users/Shared/1.png", 446, 353, f, "Test 66: ';' input" )
        check_image("/Users/Shared/test.png", "/Users/Shared/1.png", 517, 353, f, "Test 67: '(' input" )
        check_image("/Users/Shared/test.png", "/Users/Shared/1.png", 588, 353, f, "Test 68: ')' input" )
        check_image("/Users/Shared/test.png", "/Users/Shared/1.png", 659, 353, f, "Test 69: '$' input" )
        check_image("/Users/Shared/test.png", "/Users/Shared/1.png", 730, 353, f, "Test 70: '&' input" )
        check_image("/Users/Shared/test.png", "/Users/Shared/1.png", 801, 353, f, "Test 71: '@' input" )
        check_image("/Users/Shared/test.png", "/Users/Shared/1.png", 872, 353, f, "Test 72: '.' input" )
                
        check_image("/Users/Shared/test.png", "/Users/Shared/1.png", 90, 371, f, "Test 73: ',' input" )
        check_image("/Users/Shared/test.png", "/Users/Shared/1.png", 161, 371, f, "Test 74: '?' input" )
        check_image("/Users/Shared/test.png", "/Users/Shared/1.png", 232, 371, f, "Test 75: '!' input" )
        check_image("/Users/Shared/test.png", "/Users/Shared/1.png", 304, 371, f, "Test 76: '\'' input" )
        check_image("/Users/Shared/test.png", "/Users/Shared/1.png", 375, 371, f, "Test 77: '\"' input" )
        check_image("/Users/Shared/test.png", "/Users/Shared/1.png", 446, 371, f, "Test 78: '[' input" )
        check_image("/Users/Shared/test.png", "/Users/Shared/1.png", 517, 371, f, "Test 79: ']' input" )
        check_image("/Users/Shared/test.png", "/Users/Shared/1.png", 588, 371, f, "Test 80: '{' input" )
        check_image("/Users/Shared/test.png", "/Users/Shared/1.png", 659, 371, f, "Test 81: '}' input" )
        check_image("/Users/Shared/test.png", "/Users/Shared/1.png", 730, 371, f, "Test 82: '#' input" )
        check_image("/Users/Shared/test.png", "/Users/Shared/1.png", 801, 371, f, "Test 83: '%' input" )
        check_image("/Users/Shared/test.png", "/Users/Shared/1.png", 872, 371, f, "Test 84: '^' input" )
                
        check_image("/Users/Shared/test.png", "/Users/Shared/1.png", 90, 389, f, "Test 85: '*' input" )
        check_image("/Users/Shared/test.png", "/Users/Shared/1.png", 161, 389, f, "Test 86: '+' input" )
        check_image("/Users/Shared/test.png", "/Users/Shared/1.png", 232, 389, f, "Test 87: '=' input" )
        check_image("/Users/Shared/test.png", "/Users/Shared/1.png", 304, 389, f, "Test 88: '_'' input" )
        check_image("/Users/Shared/test.png", "/Users/Shared/1.png", 375, 389, f, "Test 89: '\\' input" )
        check_image("/Users/Shared/test.png", "/Users/Shared/1.png", 446, 389, f, "Test 90: '|' input" )
        check_image("/Users/Shared/test.png", "/Users/Shared/1.png", 517, 389, f, "Test 91: '~' input" )
        check_image("/Users/Shared/test.png", "/Users/Shared/1.png", 588, 389, f, "Test 92: '<' input" )
        check_image("/Users/Shared/test.png", "/Users/Shared/1.png", 659, 389, f, "Test 93: '>' input" )
        f.write("</tbody></table></body></html>")
        f.close()
    }

                  
    #frankly_map( "view:'FHServiceView'", "FEX_dragWithInitialDelayToX:y:", 512, -400 )
    #steps %{
    #Then I type \"90\" into the \"X\" text field
    #Then I type \"245\" into the \"Y\" text field
    #Then I type \"1\" into the \"Image Name\" text field
    #Then I touch the button marked "testButton"
    #Then I should see \"Match\"
    #}
end

Then /^I write results$/ do
    frankly_map( "view:'ImageTestView'", "writeResults" )
end
