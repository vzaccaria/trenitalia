filter    = require('fuzzy-filter')
_ = require('lodash')
debug     = require('debug')('as:filter')


_module = ->
          
    iface = { 
        filterBy: (pattern, array, accessor, opts) ->
            debug pattern
            indexed = _.groupBy(array, accessor) 
            names = array.map(accessor)
            filtered = filter(pattern, names, opts)
            debug filtered
            return _.flatten(_.values(_.pick(indexed, filtered)))

    }
  
    return iface
 
module.exports = _module()

# Add this to package.json:
#
#  "dependencies": {
#    "moment": "~1.7.2",
#    "underscore": "~1.4.3",
#    "underscore.string": "~2.3.1",
#    "ansi-color": "*",
#    "shelljs": "*",
#    "q": "*",
#  },