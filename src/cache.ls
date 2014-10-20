

q               = require('bluebird')
debug           = require('debug')('as:cache')




_module = (use-redis=false) ->

    if not use-redis
        db = require('levelup')(__dirname+"/../cache.db", { valueEncoding : 'json' })
        db = q.promisifyAll(db) 
        iface = { 
            open: ->
                q.resolve(true)
            put: (key, value) ->
                db.putAsync(key, value)
            get: (key) ->
                db.getAsync(key)
            close: ->
                q.resolve(false)
        }
        return iface
    else
        @client = {}

        iface = {
            open: ~>

                if _.isEmpty(@client)
                    @client = require('redis').createClient()
                    @client = q.promisifyAll(@client)

                q.resolve(true)

            put: (key, value) ~>
                @client.HMSETAsync(key, value)

            get: (key, value) ~>
                @client.hgetallAsync(key).then ->
                    if not it?
                        debug "Not found!! #key"
                        return q.reject("Invalid key")
                    else
                        return it

            close: ~>
                @client.end()
        }
 
module.exports = _module

