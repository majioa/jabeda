#!/bin/ruby

require 'pp'
require 'tmail'

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

def alertDispatcher( results )
    enabledModules = CONFIG["enabledModules"]
    if enabledModules.size > 0 then
        if CONFIG["enabledModules"].match( /.+,.+/ ) then
            enabledModules=CONFIG["enabledModules"].split(/,/, 2)
            enabledModules.each do |mod|
                doAlert( mod, results )
            end
        else
            doAlert( CONFIG["enabledModules"], results )
        end
    else
        msgDbg("No alert modules are enabled!")
    end
end

def doAlert( mod, results )
    output = Array.new
    results.each do |result|
        out = CONFIG["messageFormat"] %
        [ Time.at(result[0].to_i).strftime( CONFIG["timeFormat"] ),
          result[2],
          result[1],
          result[3].upcase,
          result[4],
          result[5] ]
        output << out
    end

    case mod
    when "console":
        output.each do |out|
            pp out
        end
    when "email":
        output.each do |out|
            mail = TMail::Mail.new
            mail.date = Time.now
            mail.from = "Yabeda OVZ watcher <yabeda@cryo.net.ru>"
            mail.to = "pavlov.konstantin@gmail.com"
            mail.subject = "Problem detected!"
            mail.mime_version = "1.0"
            mail.set_content_type 'multipart', 'mixed'
            mail.transfer_encoding = "8bit"
            mail.body = nil
            message = TMail::Mail.new
            message.set_content_type('text', 'plain', {"charset" =>"utf-8"})
            message.transfer_encoding = '7bit'
            message.body = out
            mail.parts.push(message)

            IO.popen("/usr/sbin/sendmail -oem -oi -t", "w") { |sendmail|
                sendmail.puts mail.encoded()
            }
        end

    end
end

# typical workflow:
# getProcPaths() -> getResource() -> currentData
# readFile(state) -> validateData() -> oldData
# compareData -> results
# alertDispatcher(results) -> doAlert()
# writeFile(state, currentdata)

CONFIG = getConfig( CONFIGFILE ) or return 0

oldData = validateData( readFile( STATEFILE ) )

currentData = getResource( getProcPaths() )

if oldData and currentData then
    results = compareData( oldData, currentData )
    alertDispatcher(results)
end

#if currentData then
#    writeFile( STATEFILE, currentData)
#end
