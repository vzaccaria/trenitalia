debug                    = require('debug')('as:main')
_                        = require('lodash')
filter                   = require('fuzzy-filter')
q                        = require('bluebird')
ev                       = require('extract-values')
moment                   = require('moment')
urlencode                = require('urlencode')
{item, feedback, noitem} = require('./feedback')
S                        = require('string');



_module = (cachedb, limit) ->
    @queries = []

    iface = { 
        addquery: (s) ~>
            cachedb.get('queries')
            .then (queries) ~>
                @queries = _.values(queries)
            .catch ~>
                @queries = []
            .then ~>
                debug @queries
                found = false
                for i,r of @queries 
                    if s.substr(0, r.value.length) == r.value 
                        @queries[i] = {
                            value: s
                            date: moment()
                        }
                        found = true
                        break
                if not found 
                    @queries.push {
                        value: s
                        date: moment()
                    }
                @queries = _.sortBy(@queries, -> -1 * moment(it.date).valueOf())
                @queries = _.first(@queries, limit)
                debug "Writing queries #{JSON.stringify(@queries,0,4)}"
                cachedb.put('queries',@queries)


        showqueries: ->
            cachedb.get('queries')
            .then (queries) ->
                items = queries.map (v) ->
                    return (item({title: v.value, subtitle: "query cached", autocomplete: v.value, valid: true}))
                feedback items
            .catch ->
                items = [ "" ] 
                feedback items               
    }
  
    return iface
 
module.exports = _module

