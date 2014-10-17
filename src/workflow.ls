
# var alfredo = 'alfredo'

# /* Just an example */
# alfredo.feedback(new alfredo.Item({title: "you item name", valid: false}))

debug     = require('debug')('as:main')
debug "1"
_         = require('lodash')
debug "2"
filter    = require('fuzzy-filter')
debug "3"
q         = require('bluebird')
debug "4"
ev        = require('extract-values')
debug "5"
moment    = require('moment')
debug "7"
urlencode = require('urlencode')
debug "8"
cachedb   = require('./cache')(false)
debug "9"
{item, feedback, noitem} = require('./feedback')
debug "10"
S = require('string');
debug "11"

# The cached-data

require! winston

winston.add(winston.transports.File, { filename: '/Users/zaccaria/.alfred-inspect.log', level: 'silly', json: false, prettyPrint: true });
winston.remove(winston.transports.Console);

args = process.argv[2]

s  = -> q.promisifyAll(require('superagent'))

url = 'http://www.viaggiatreno.it/viaggiatrenonew/resteasy/viaggiatreno' 

o = (e, v) ->
    { expr: e, value: v }

train-search = [
    o "!`numeroTreno`"
    o "`arrivo` < `hint`"
    o "`arrivo` <"
    o "`partenza` > `hint`"
    o "`partenza` >"
    o "$u", { +update-cache } # Update cache
    o "$p", { +process-cache } # Update cache
    o "$d", { +dump-cache }
    o "`selezionaStazione`"
    ... ]

parse = (l) ->
    for c in train-search
        ps = ev(l, c.expr, { lowercase: true, whitespace: 1, delimiters: ["`", "`"] })
        if ps?
            return c.value if c.value?
            return ps
    return undefined

update-cache = ->
    rq = q.all([ 0 to 23 ].map ->
        ad = "#url/elencoStazioni/#it"
        debug "Getting #ad"
        s!.get(ad).endAsync())

    rq.then (resarr) -> 
        fs  = require('fs')
        fs  = q.promisifyAll(fs)
        dta = _.flatten(_.map resarr, (.body))
        fs.writeFileAsync("#{__dirname}/../cache.json", JSON.stringify(dta, 0, 4), 'utf8')

process-data = ->
    cachedb.open!.then ->
        debug "Processing data.."
        data = require("#{__dirname}/../cache.json")

        data = _.map data, -> 
            it.nome = it.localita.nomeBreve.toLowerCase()
            it.nomeOrig = it.localita.nomeBreve
            return it

        dta = _.indexBy(data, (.nome))
        cache = {}

        cache.hash = _.mapValues dta, -> 
            { nome: it.nome, nomeOrig: it.nomeOrig, codice: it.codiceStazione, lat: it.lat, lon: it.lon } 

        for k,v of cache.hash
            cachedb.put(k,v)
        
        cache.names = _.map cache.hash, (.nome)

        cachedb.put('names', cache.names)
    .then ->
        cachedb.close!


showStazione = (name) ->
    cachedb.open!.then ->
        cachedb.get('names').then ->
            allnames = _.values(it)
            filt = filter(name, allnames, {limit:10})
            q.all filt.map ->
                cachedb.get(it).then (data) ->
                    name = data.nomeOrig
                    url = "www.google.com/maps/preview/@#{data.lat},#{data.lon},14z"
                    return (item({title: name, subtitle: "Open #name in google maps", icon: icon('station'), autocomplete: "#name >", valid: true, arg: url}))
            .then (items) ->
                feedback items
    .then -> 
        cachedb.close!

show-error = (e,s) ->
    feedback([item({title: e, subtitle: s, valid: false})])

show-info = (e,s) ->
    feedback([item({title: e, subtitle: s, valid: false})])

getInfoTreno = (codiceStazione, codiceTreno) ->

# curl 'http://www.viaggiatreno.it/viaggiatrenonew/resteasy/viaggiatreno/partenze/S01301/Wed%20Oct%2015%202014%2016:57:38%20GMT+0200%20(CEST)' -H 'Accept-Encoding: gzip,deflate,sdch' -H 'Accept-Language: en-US,en;q=0.8,it;q=0.6,nb;q=0.4' -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/38.0.2125.101 Safari/537.36' -H 'Accept: application/json' -H 'Referer: http://www.viaggiatreno.it/viaggiatrenonew/' -H 'Cookie: LANG=it; JSESSIONID=00006Fflk-LUexYivZ_BCqL-Erl:16n78sun9; s_cc=true; s_vs=1; s_cpc=1; s_nr=1413385028942-Repeat; ttcc=1413385028943; s_sq=%5B%5BB%5D%5D' -H 'Connection: keep-alive' --compressed


prod = ->
    return _.reduceRight(arguments, (a,b) ->
        _.flatten(_.map(a,(x) -> _.map b, (y) -> x.concat(y)), true)
    , [ [] ])

getTreniPartenza = (codiceStazione) ->
    timefmt = "ddd MMM D YYYY H:m:s"
    date    = urlencode(moment().format(timefmt))
    lurl     = "#url/partenze/#codiceStazione/#date"
    s!.get("#lurl").endAsync().then ->
        departureTrains = it.body.map ->
            binario = ""
            confirmed = false
            if it.binarioEffettivoPartenzaDescrizione?
                binario = that+" - Conf."
                confirmed = true
            else
                binario = S(it.binarioProgrammatoPartenzaDescrizione).humanize()

            { numero: it.numeroTreno, destinazione: it.destinazione, orario: moment(it.orarioPartenza), confirmed: confirmed, binario: binario, ritardo: it.ritardo}

getTreniArrivo = (codiceStazione) ->
    timefmt = "ddd MMM D YYYY H:m:s"
    date    = urlencode(moment().format(timefmt))
    lurl     = "#url/arrivi/#codiceStazione/#date"
    s!.get("#lurl").endAsync().then ->
        arrivalTrains = it.body.map ->
            binario = ""
            confirmed = false
            if it.binarioEffettivoArrivoDescrizione?
                binario = that+" - Conf."
                confirmed = true
            else
                binario = S(it.binarioProgrammatoArrivoDescrizione).humanize()

            { numero: it.numeroTreno, origine: it.origine, orario: moment(it.orarioArrivo), confirmed: confirmed, binario: binario, ritardo: it.ritardo }

icon = ->
        "#{__dirname}/../images/#it.png"

getIconTrain = (train) ->
    

    now = moment()
    tor = moment(train.orario)
    tor.add(train.ritardo, 'm')
    if now.isAfter(tor) 
        return icon('past')
    if train.confirmed
        return icon('late')
    if now.isBefore(train.orario)
        return icon('future')
    return icon('futurec')


showDettagliStazione = (stazione, options) ->
    if options.partenze?
        getTreniPartenza(stazione.codice).then (treni-in-partenza) ->
            if options.hint?
                treni-in-partenza = require('./filter').filterBy(options.hint, treni-in-partenza, (.destinazione))
            q.all treni-in-partenza.map (train) ->
                ditem = 
                    title: ("#{stazione.nomeOrig} > #{S(train.destinazione).humanize()}")
                    subtitle: "Departs #{moment(train.orario).format("HH:mm")} (Rit. #{train.ritardo}) - Track #{train.binario}"
                    autocomplete: "!#{train.numero}"
                    valid: true
                    icon: getIconTrain(train)
                return item(ditem)                    
            .then (items) ->
                winston.info items
                feedback(items)
    else 
        getTreniArrivo(stazione.codice).then (treni-in-arrivo) ->
            if options.hint?
                treni-in-arrivo = require('./filter').filterBy(options.hint, treni-in-arrivo, (.origine))
            q.all treni-in-arrivo.map (train) ->
                ditem = 
                    title: ("#{stazione.nomeOrig} < #{S(train.origine).humanize()}")
                    subtitle: "Arrives #{moment(train.orario).format("HH:mm")} (Rit. #{train.ritardo}) - Track #{train.binario}"
                    autocomplete: "!#{train.numero}"
                    valid: true
                    icon: getIconTrain(train)
                return item(ditem)                    
            .then (items) ->
                winston.info items
                feedback(items)     


showTreni = (stazione, options) ->
    cachedb.open!.then ->
        cachedb.get('names').then ->
            names = _.values(it)
            if not (stazione in names)
                show-error("Sorry, no station found", "Type in an existing station or tab to autocomplete")
            else
                cachedb.get(stazione)
                .then (source) ->
                    showDettagliStazione(source, options)
                .catch ->
                    show-error("Sorry, no station found", "Type in an existing station or tab to autocomplete")
    .then ->
        cachedb.close!

debug process.argv 

if args?
    parsed = parse(args)
    debug parsed
    if parsed?.update-cache?
        update-cache()
    if parsed?.process-cache?
        process-data()
    if parsed?.selezionaStazione?
        showStazione(parsed.selezionaStazione)
    if parsed?.partenza?
        showTreni(parsed.partenza, { hint: parsed.hint, +partenze} )
    if parsed?.arrivo?
        showTreni(parsed.arrivo, { hint: parsed.hint, +arrivi} )



