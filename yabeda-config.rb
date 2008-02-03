#!/bin/ruby

require 'yabeda-common.rb'

CONFIGFILE = "/etc/yabeda/yabeda.conf"
STATEFILE = "/var/lib/yabeda/state"

def getConfig( file )

    contents = readFile( file )
    opt = Hash.new

    if contents then
        contents.each do |line|
            line.chomp!
            ( key, arg ) = line.split( /=/, 2 )
            opt[ key ] = arg
        end
        return opt
    end
    return false
end

