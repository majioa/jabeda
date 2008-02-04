#!/bin/ruby

require 'yabeda-config.rb'

def msgDbg( error )
    debug = getParameter('debug')

    error = getTime() + ': ' + error

    debug and puts error
end
