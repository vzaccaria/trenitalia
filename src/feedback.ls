debug = require('debug')('as:feedback')
S = require('string')

_module = ->
          
    iface = { 
        item: (obj) ->
            let @=obj
            
                @valid ?= false
                @subtitle ?= @title
                @autocomplete ?= 'none'
                @icon ?= 'icon.png'
                @argn ?= 'noarg'

                v = 
                    | @valid => 'yes'
                    | otherwise => no

                return """
                <item autocomplete=\"#{S(@autocomplete).escapeHTML()}\" 
                      uid=\"\" 
                      valid=\"#{v}\" 
                      arg=\"#{@arg}\">
                      <title>#{S(@title).escapeHTML()}</title>
                  <subtitle>#{S(@subtitle).escapeHTML()}</subtitle>
                  <icon>#{@icon}</icon>
                </item>
                """

        noitem: ->
            return ""

        feedback: (items) ->
            console.log "<items>"
            console.log (items * '\n')
            console.log "</items>"
    }
  
    return iface
 
module.exports = _module()
