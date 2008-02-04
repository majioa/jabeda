#!/bin/ruby

require 'yabeda-common.rb'

def msgDbg( error )
    error = getTime() + ": " + error
    CONFIG["debug"] and puts error
end
