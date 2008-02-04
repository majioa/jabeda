#!/bin/ruby

require 'yabeda-logging.rb'
require 'yabeda-config.rb'

def getHostname()
    hostname_allowedregex = getParameter('hostname_allowedregex')
    hostname_suffix = getParameter('hostname_suffix')

    hostname = ENV['HOSTNAME'].to_s
    if !hostname.match( /#{hostname_allowedregex}/ ) then
        hostname += hostname_suffix
    end
    return hostname
end

def getTime()
        return Time.now.to_i.to_s
end

def readFile( file )
    if ( FileTest.exists?( file ) ) and ( FileTest.readable_real?( file ) ) then
        contents = File.read( file )
        return contents
    end
    msgDbg( "Failed to open and/or read file #{file}" )
    return false
end

def writeFile( file, contents )
    filedescr = File.open( file, 'w+' )
    contents.each { |arr|
        line = arr.join(' ')
        filedescr.write( line + "\n" )
    }
    filedescr.close
    return true
end

