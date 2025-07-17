=begin

Copyright 2025, PHƯỚC TUẤN
All Rights Reserved

License: TUẤN HUY FURNITURE APPROVED
Author: PHƯỚC TUẤN
Organization: TUẤN HUY FURNITURE 
Name: Ruby Code Ediror - Alex
Version: ScriptVersion
SU Version: 2022 
Date: Date
Description: ScriptDescription 
Usage: ScriptUsageInstructions 
History:
    1.0.0 YYYY-MM-DD Description of changes
    
=end

require 'sketchup.rb'
require 'extensions.rb'

# Wrap in your own module. Start its name with a capital letter

module LPT_SOLUTION

  module LPT_EXTENSION

    # Load extension
    my_extension_loader = SketchupExtension.new( 'LPT_SOLUTION' , 'LPT_SOLUTION/LPT_EXTENSION.rb' )
    my_extension_loader.copyright = 'Copyright 2025 by L.P.T' 
    my_extension_loader.creator = 'Phước Tuấn' 
    my_extension_loader.version = '1.0.1' 
    my_extension_loader.description = 'To do useful things'
    Sketchup.register_extension( my_extension_loader, true )

  end  # module MY_ThisExtension
  
end  # module MY_Extensions