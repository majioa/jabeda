#!/bin/ruby

require 'yabeda-common.rb'

DEBUG = true

def msgDbg( error )
    error = getTime() + ": " + error
    DEBUG and puts error
end
