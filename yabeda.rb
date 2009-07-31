#!/usr/bin/env ruby

# vim: set fdm=marker :

require 'pp'
require 'tmail'
require 'socket'
require 'dbi'
require 'yaml'
require 'xmpp4r'

$config = {
    :enabled                   =>  false,
    :configfile                =>  "/etc/yabeda/yabeda.conf",
    :statefile                 =>  "/var/lib/yabeda/state",
    :debug                     =>  true,
    :disallowed_proc           =>  ".+\/0$",
    :hostname_allowedregex     =>  ".+",
    :hostname_suffix           =>  ".cryo.net.ru",
    :time_format               =>  "%H:%M:%S %d-%m-%Y",
    :message_format            =>  "%s: CT %s on %s: %s failcnt changed from %s to %s.",
    :enabled_modules           =>  "console",
    :mail_from                 =>  "Yabeda OVZ watcher <insert@lame-name.here>",
    :mail_to                   =>  ["foobar@domain.tld", "baz@domain.tld"],
    :subject_format            =>  "VPS%d: %s failcnt increased!",
    :mysql_host                =>  "localhost",
    :mysql_db                  =>  "yabeda",
    :mysql_port                =>  "3306",
    :mysql_user                =>  "yabeda",
    :mysql_password            =>  "yabeda",
    :mysql_table               =>  "stats",
    :alive_notify              =>  false,
    :events_table              =>  "events",
    :jabber_jid                =>  "bot@localhost/bot",
    :jabber_password           =>  "bot",
    :jabber_to                 =>  ["admin@localhost", "monitoring@localhost"]
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

    if !configfile then
        puts 'Error opening config file.'
        exit 1
    end

    $config.merge!(YAML.load(File.open(configfile)))
end

# }}}

# {{{ Debug functions
def msgDbg( error )
    error = getTime() + ': ' + error

    $config[:debug] and puts error
end

# }}}

# {{{ Helper functions

def getHostname()
    hostname = Socket.gethostname
    if !hostname.match( /#{$config[:hostname_allowedregex]}/ ) then
        hostname += $config[:hostname_suffix]
    end
    return hostname
end

def getTime()
    return Time.now.to_i.to_s
end

# }}}

# {{{ MySQL functions

def connectSql()
    dbh = DBI.connect("DBI:Mysql:database=#{$config[:mysql_db]};host=#{$config[:mysql_host]};port=#{$config[:mysql_port]}", $config[:mysql_user], $config[:mysql_password])
    return dbh
end

# }}}

# {{{ Acquiring data
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

    paths = Dir["/proc/bc/*"].sort
	if paths then
        paths.each { |path|
            if FileTest.directory?( path ) and !path.match( /#{$config[:disallowed_proc]}/ ) then
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

    if results.size > 0
        return results
    else
        msgDbg("Data unchanged")
        return false
    end
end

# }}}

# {{{ Alert generation

def alertDispatcher( results )

    enabled_modules = $config[:enabled_modules]

    if enabled_modules.match( /.+,.+/ ) then
        enabled_modules.split(/,/).each do |mod|
            doAlert( mod, results )
        end
    else
        doAlert( enabled_modules, results )
    end
end

def doAlert( mod, results )
    message_format = $config[:message_format]
    time_format = $config[:time_format]
    subject_format = $config[:subject_format]

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
    when 'console' then
        output.each do |out|
            pp out
        end
    when 'mysql' then
        table = $config[:mysql_table]
        sqlstring = "INSERT `#{table}` (time, hostnode, veid, parameter, oldvalue, currentvalue) values "

        results.each do |out|
            sqlstring += "( FROM_UNIXTIME(" + out[0].to_s + "), '"
            sqlstring += out[1].to_s + "', '"
            sqlstring += out[2].to_s + "', '"
            sqlstring += out[3].to_s.upcase + "', '"
            sqlstring += out[4].to_s + "', '"
            sqlstring += out[5].to_s + "'), "
        end
        sqlstring = sqlstring[0..-3]

        msgDbg( sqlstring )

        dbh = connectSql()
        if dbh
            begin
                push = dbh.execute(sqlstring)
                push.finish
            rescue DBI::DatabaseError => a
                puts "An error occurred"
                puts "Error code: #{a.err}"
                puts "Error message: #{a.errstr}"
                puts "Error SQLSTATE: #{a.state}"
            end
        end
    when 'email' then
        output.each do |out|
            mail = TMail::Mail.new
            mail.date = Time.now
            mail.from = $config[:mail_from]
            mail.to = $config[:mail_to].join(",")
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
    when 'jabber' then
        jabberid = Jabber::JID::new( $config[:jabber_jid] )
        jabberpwd = $config[:jabber_password]
        jabberto = $config[:jabber_to]
        client = Jabber::Client::new( jabberid, true )
        begin
        client.connect
        client.auth( jabberpwd )
        jabberto.each do |to|
            output.each do |out|
                subject = out[0]
                body = out[1]
                message = Jabber::Message::new(to, body).set_type(:normal).set_id('1').set_subject(subject)
                client.send(message)
            end
        end
        client.close
        rescue Jabber::Error => a
            puts "An error occurred"
            puts "Error code: #{a.err}"
            puts "Error message: #{a.errstr}"
        end
    end
end

# }}}

# {{{ alive check // now in SQL only.

def aliveDispatcher()
    table = $config[:events_table]
    hostname = getHostname()
    date = Time.now.to_i
    sqlstring = "SELECT COUNT(hostname) FROM #{table} WHERE hostname='#{hostname}'"
    dbh = connectSql()
    if dbh
        begin
            push = dbh.select_one(sqlstring)
            case push[0]
            when 0 then
                sqlstring = "INSERT #{table} (hostname, ping_time) VALUES ('#{hostname}', FROM_UNIXTIME( '#{date}' ) )"
                insert = dbh.execute(sqlstring)
                insert.finish
            when 1 then
                sqlstring = "UPDATE #{table} SET hostname='#{hostname}', ping_time=FROM_UNIXTIME('#{date}') WHERE hostname='#{hostname}';"
                update = dbh.execute(sqlstring)
                update.finish
            else
                sqlstring = "DELETE from #{table} where hostname = '#{hostname}'"
                delete = dbh.execute(sqlstring)
                delete.finish
                aliveDispatcher()
            end
            dbh.disconnect
        rescue DBI::DatabaseError => a
            puts "An error occurred"
            puts "Error code: #{a.err}"
            puts "Error message: #{a.errstr}"
            puts "Error SQLSTATE: #{a.state}"
        end
    end
end

# }}}

# {{{ Something happened, let's throw admins a mail.

def vsePloho()
    hostname = getHostname()
    mail = TMail::Mail.new
    mail.date = Time.now
    mail.from = $config[:mail_from]
    mail.to = $config[:mail_to].join(",")
    mail.subject = "Yabeda failed to do alerts and ping on #{hostname}"
    mail.mime_version = "1.0"
    mail.set_content_type 'multipart', 'mixed'
    mail.transfer_encoding = "8bit"
    message = TMail::Mail.new
    message.set_content_type('text', 'plain', {'charset' =>'utf-8'})
    message.transfer_encoding = '7bit'
    message.body = "Yabeda failed to do alert dispatching and insert stuff to SQL at the same time on #{hostname} at #{Time.now}."
    mail.parts.push(message)
    IO.popen('/usr/sbin/sendmail -oem -oi -t', 'w') { |sendmail|
        sendmail.puts mail.encoded()
    }
end

# }}}

# {{{ Main program

def main()
# typical workflow:
# getProcPaths() -> getResource() -> currentData
# readFile(state) -> validateData() -> oldData
# compareData -> results
# alertDispatcher(results) -> doAlert()
# writeFile(state, currentdata)

    getConfig( $config[:configfile] )

    if !$config[:enabled] then
        msgDbg( "Not doing any checks, bailing out..." )
        exit 0
    end

    oldData = validateData( readFile( $config[:statefile] ) )

    currentData = getResource( getProcPaths() )

    if oldData.size > 0 and currentData.size > 0 then
        begin
            results = compareData( oldData, currentData )
            if results then
                alertDispatcher(results)
            end
            $config[:alive_notify] and aliveDispatcher()
        rescue
            vsePloho()
            puts "Couldnt make a transaction of alert dispatching and pinger"
            exit 1
        end
    end

    if currentData then
        writeFile( $config[:statefile], currentData)
    end
end
# }}}

if ARGV.size == 2 and ARGV[0] == "configdump" then
    File.open( ARGV[1], 'w' ) do |out|
        YAML.dump( $config, out )
    end
elsif ARGV.size == 0 then
    main()
else
    puts " Unknown command: #{ARGV[0]}"
    puts " Usage: #{__FILE__} configdump /path/to/dump.conf"
end
