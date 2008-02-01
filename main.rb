#!/bin/ruby

require 'pp'

stateFile = "/var/lib/yabeda/state"
configFile = "/etc/yabeda/yabeda.conf"

DEBUG = true

def msgDbg( error )
    error = getTime() + ": " + error
    DEBUG and puts error
end

def getHostname()
    hostname = ENV['HOSTNAME'].to_s
    if !hostname.match( /#{CONFIG["hostNameAllowedRegex"]}/ ) then
        hostname += CONFIG["hostNameSuffix"]
    end
    return hostname
end

def getTime()
    return Time.now.to_i.to_s
end

def getArray()
    return Array.new
end

def readFile( file )
    if ( FileTest.exists?( file ) ) then
        contents = File.read( file )
        return contents
    end
    msgDbg( "Failed to open and/or read file #{file}" )
    return false
end

def validateData( data )

    if data != false then
        validatedContent = getArray()
        data.each { |line|
            if line =~ /.+\s.+\d+\s\w+\s\d+$/ then 
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
    returnpaths = getArray()

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
    output = getArray()
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

def saveData( file, contents )
    filedescr = File.open( file, "w+" )
    contents.each { |arr|
        line = arr.join(" ")
        filedescr.write( line + "\n" )
    }
    filedescr.close
    return true
end

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
    output = getArray()
    results.each do |result|
        out = printf("%s: vps%s%s %s %s changed from %s to %s.\n", 
               Time.at(result[0].to_i).strftime("%H:%M:%S %d-%m-%Y"),
               result[2],
               CONFIG["hostNameSuffix"],
               result[1],
               result[3],
               result[4],
               result[5])
        output << out
    end
    return output
end

CONFIG = getConfig( configFile ) or return 0

oldData = validateData( readFile( stateFile ) )

currentData = getResource( getProcPaths() )

results = compareData( oldData, currentData )

pp doStuff(results)

#saveData(stateFile, currentData)
