#!/bin/ruby

require 'pp'

require 'yabeda-common.rb'
require 'yabeda-config.rb'
require 'yabeda-logging.rb'

def validateData( data )

    if data != false then
        validatedContent = Array.new
        data.each { |line|
            if line =~ /\d+\s.+\d+\s\w+\s\d+$/ then
                line = line.split(" ")
                validatedContent << line
            end
        }
        return validatedContent
    end
    msgDbg( "Data validation failed" )
    return false
end

def getProcPaths()
    returnpaths = Array.new

    paths = Dir["/proc/bc/*"].sort
	if paths then
        paths.each { |path|
            if FileTest.directory?( path ) and !path.match( /#{CONFIG["disProc"]}/ ) then
	            returnpaths << path
            end
	    }
		return returnpaths
	end
	return false
end

def getResource ( paths )
    output = Array.new
    time = getTime()
    hostname = getHostname()

    paths.each { |path|
        veid = path.match( /\d+$/ )[0]
        resources = readFile( path + "/resources" )
        if resources then
            resources.each { |line|
                line.strip!
                if line =~ /^\w+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+$/ then
                    resource = line.match( /^\w+/ )[0]
                    failcnt = line.match( /\d+$/ )[0]
                    output << [ time.to_s, hostname, veid, resource, failcnt ]
                end
        	}
        else
            return false
        end
    	}
    return output
end

def compareData( oldData, currentData )
    results = Array.new
    oldData.each do |old|
        veid = old[2]
        param = old[3]
        value = old[4]
        currentData.each do |cur|
            if ( old[2] == cur[2] ) and (old[3] == cur[3] ) and (old[4] != cur[4] )then
                        results << [ cur[0], cur[1], cur[2], cur[3], old[4], cur[4] ]
            end
        end
    end
    return results
end

def doStuff( results )
    output = Array.new
    results.each do |result|
        out = printf( CONFIG["messageFormat"],
               Time.at(result[0].to_i).strftime( CONFIG["timeFormat"] ),
               result[2],
               result[1],
               result[3].upcase,
               result[4],
               result[5])
        output << out
    end
    return output
end

CONFIG = getConfig( CONFIGFILE ) or return 0

oldData = validateData( readFile( STATEFILE ) )

currentData = getResource( getProcPaths() )

if oldData and currentData then
    results = compareData( oldData, currentData )
    pp doStuff(results)
end

#if currentData then
#    writeFile( STATEFILE, currentData)
#end
