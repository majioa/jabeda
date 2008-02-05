#!/usr/bin/env ruby

# vim: set fdm=marker :

require 'pp'
require 'tmail'

CONFIGFILE = '/etc/yabeda/yabeda.conf'
STATEFILE = '/var/lib/yabeda/state'

DEFAULTS = {
    'debug'                     =>  true,
    'disallowed_proc'           =>  '.+\/0$',
    'hostname_allowedregex'     =>  '.+',
    'hostname_suffix'           =>  '.cryo.net.ru',
    'time_format'               =>  '=%H:%M:%S %d-%m-%Y',
    'message_format'            =>  '%s: CT %s on %s: %s failcnt changed from %s to %s.',
    'enabled_modules'           =>  'console',
    'mail_from'                 =>  'Yabeda OVZ watcher <yabeda@cryo.net.ru>',
    'mail_to'                   =>  'pavlov.konstantin@gmail.com',
    'subject_format'            =>  'VPS%d: %s failcnt -> %s!'
}

# {{{ Common IO functions

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

# }}}

# {{{ Configuration functions
def getConfig( file )

    configfile = FileTest.exists?( file ) ? file : './yabeda.conf'
    configfile = FileTest.exists?( configfile ) ? configfile : false

    if configfile == false then
        puts 'Error opening config file.'
        exit 0
    end

    contents = readFile( configfile )
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

def getParameter( param )
    real_param = CONFIG[ param ].nil? ? DEFAULTS[ param ] : CONFIG[ param ]
    return real_param
end

# }}}

# {{{ Debug functions
def msgDbg( error )
    debug = getParameter('debug')

    error = getTime() + ': ' + error

    debug and puts error
end

# }}}

# {{{ Helper functions

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

# }}}

# {{{ Acquriing data
def validateData( data )
    unless data == false
        validatedContent = Array.new
        data.each { |line|
            if line =~ /\d+\s.+\d+\s\w+\s\d+$/ then
                line = line.split(" ")
                validatedContent << line
            end
        }
        return validatedContent
    else
        msgDbg( 'Data validation failed' )
        return false
    end
end

def getProcPaths()
    returnpaths = Array.new
    disregex = getParameter('disallowed_proc')

    paths = Dir["/proc/bc/*"].sort
	if paths then
        paths.each { |path|
            if FileTest.directory?( path ) and !path.match( /#{disregex}/ ) then
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
        resources = readFile( path + '/resources' )
        unless resources.nil?
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
                        #            time    host    veid    param   value   value
            end
        end
    end
    return results
end

# }}}

# {{{ Alert generation

def alertDispatcher( results )
    enabled_modules = getParameter('enabled_modules')

    if enabled_modules.match( /.+,.+/ ) then
        enabled_modules.split(/,/, 2).each do |mod|
            doAlert( mod, results )
        end
    else
        doAlert( enabled_modules, results )
    end
end

def doAlert( mod, results )
    message_format = getParameter('message_format')
    time_format = getParameter('time_format')
    subject_format = getParameter('subject_format')

    output = Array.new
    results.each do |result|
        body = message_format %
        [ Time.at(result[0].to_i).strftime( time_format ),
          result[2],
          result[1],
          result[3].upcase,
          result[4],
          result[5] ]
        subject = subject_format %
        [ result[2],
          result[3].upcase,
          result[5]
        ]
        output << [ subject, body ]
    end

    case mod
    when 'console':
        output.each do |out|
            pp out
        end
    when 'email':
        mail_from = getParameter('mail_from')
        mail_to = getParameter('mail_to')

        output.each do |out|
            mail = TMail::Mail.new
            mail.date = Time.now
            mail.from = mail_from
            mail.to = mail_to
            mail.subject = out[0]
            mail.mime_version = "1.0"
            mail.set_content_type 'multipart', 'mixed'
            mail.transfer_encoding = "8bit"
            mail.body = nil
            message = TMail::Mail.new
            message.set_content_type('text', 'plain', {'charset' =>'utf-8'})
            message.transfer_encoding = '7bit'
            message.body = out[1]
            mail.parts.push(message)

            IO.popen('/usr/sbin/sendmail -oem -oi -t', 'w') { |sendmail|
                sendmail.puts mail.encoded()
            }
        end

    end
end

# }}}

# {{{ Main program

# typical workflow:
# getProcPaths() -> getResource() -> currentData
# readFile(state) -> validateData() -> oldData
# compareData -> results
# alertDispatcher(results) -> doAlert()
# writeFile(state, currentdata)

CONFIG = getConfig( CONFIGFILE )

oldData = validateData( readFile( STATEFILE ) )

currentData = getResource( getProcPaths() )

if oldData and currentData then
    results = compareData( oldData, currentData )
    alertDispatcher(results)
end

#if currentData then
#    writeFile( STATEFILE, currentData)
#end
# }}}
