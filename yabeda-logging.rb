#!/bin/ruby

DEBUG = true

def msgDbg( error )
    error = Time.now.to_i.to_s + ": " + error
    DEBUG and puts error
end
