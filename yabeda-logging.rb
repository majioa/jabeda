#!/bin/ruby

require 'yabeda-common.rb'

def msgDbg( error )
    error = getTime() + ': ' + error
    debug = CONFIG['debug'].nil? ? DEFAULTS['debug'] : CONFIG['debug']
    debug and puts error
end
