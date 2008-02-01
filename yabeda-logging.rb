#!/bin/ruby

require 'yabeda-time.rb'

DEBUG = true

def msgDbg( error )
    error = getTime() + ": " + error
    DEBUG and puts error
end
