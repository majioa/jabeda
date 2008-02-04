#!/bin/ruby

require 'yabeda-common.rb'

CONFIGFILE = '/etc/yabeda/yabeda.conf'
STATEFILE = '/var/lib/yabeda/state'

defaults = {
    'debug'                     =>  true,
    'disallowed_proc'           =>  '.+\/0$',
    'hostname_allowedregex'     =>  '.+',
    'hostname_suffix'           =>  '.cryo.net.ru',
    'time_format'               =>  '=%H:%M:%S %d-%m-%Y',
    'message_format'            =>  '%s: CT %s on %s: %s changed from %s to %s.',
    'enabled_modules'           =>  'console',
    'mail_from'                 =>  'Yabeda OVZ watcher <yabeda@cryo.net.ru>',
    'mail_to'                   =>  'pavlov.konstantin@gmail.com',
    'mail_subject'              =>  'Problem detected!'
}

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

CONFIG = getConfig( CONFIGFILE )

def getParameter( param )
    real_param = CONFIG[ param ].nil? ? DEFAULTS[ param ] : CONFIG[ param ]
    return real_param
end
