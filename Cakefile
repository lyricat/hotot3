{exec} = require 'child_process'
# exec = require "exec-sync"
fs = require 'fs'

DIST_BASE = "dist"
SRC_BASE = "core"

COFFEE_SRC = "#{SRC_BASE}/scripts"
LESS_SRC = "#{SRC_BASE}/styles"

JS_DIST = "#{DIST_BASE}/scripts"
CSS_DIST = "#{DIST_BASE}/styles"
MEDIA_LIST = ["icons", "images", "dialogs/*", "partials/*", "manifest.json", "index.html", "sandbox.html"]

lastChange = {}

copyFile = (src, dist) ->
    console.log "copy #{src} to #{dist}"
    exec("cp -a #{src} #{dist}")

handleMedia = (fn) ->
    for item in MEDIA_LIST
        if item[item.length - 1] == '*' # files in the dir
            item = item.substring(0, item.length - 1)
            files = fs.readdirSync("#{SRC_BASE}/#{item}")
            for file in files
                fullpath = "#{SRC_BASE}/#{item}/#{file}"
                # st = fs.statSync(fullpath)
                # if st.isDirectory() # ignore directory
                #     continue
                fn(fullpath, "#{DIST_BASE}/#{item}/#{file}")
        else
            fn("#{SRC_BASE}/#{item}", "#{DIST_BASE}/")


handleCoffeeFiles = (fn)->
    if not fs.existsSync(JS_DIST)
        fs.mkdirSync(JS_DIST)
    fs.readdir(COFFEE_SRC, (err, files) ->
        for file in files
            file = "#{COFFEE_SRC}/#{file}"
            fn file
    )

handleLessFiles = (fn)->
    if not fs.existsSync(CSS_DIST)
        fs.mkdirSync(CSS_DIST)
    fs.readdir(LESS_SRC, (err, files) ->
        for file in files
            file = "#{LESS_SRC}/#{file}"
            fn file
    )

compileCoffee = (file) =>
    if file.lastIndexOf('.coffee') == file.length - 1 - 'coffee'.length
        console.log "Compile coffee", file
        exec "coffee -c -o #{JS_DIST} #{file}", (err, stdout, stderr) ->
            return console.error err if err
            console.log "Compiled #{file}"
    else
        _file = file.split('/')
        _file = _file[_file.length - 1]
        console.log "copy only", file
        copyFile(file, "#{JS_DIST}/#{_file}")

compileLess = (file) =>
    _file = file.split('/')
    _file = _file[_file.length - 1]
    if file.lastIndexOf('.less') == file.length - 1 - 'less'.length
        console.log "Compile less", file
        exec "lessc #{file} #{CSS_DIST}/#{_file.replace('.less', '.css')}", (err, stdout, stderr) ->
            return console.error err if err
            console.log "Compiled #{file}"
    else
        console.log "copy only", file
        copyFile(file, "#{CSS_DIST}/#{_file}")

watchFile = (file, fn) ->
    lastChange[file] = 0
    try
        fs.watch file, (event, filename) ->
            return if event isnt 'change'
            # ignore repeated event misfires
            fn file if Date.now() - lastChange[file] > 1000
            lastChange[file] = Date.now()
    catch e
        console.log "Error watching #{file}"

watchCoffee = (file) ->
    watchFile file, compileCoffee

watchLess = (file) ->
    watchFile file, compileLess

watchMedia = (src, dist) ->
    lastChange[src] = 0
    try
        fs.watch src, (event, filename) =>
            return if event isnt 'change'
            # ignore repeated event misfires
            copyFile src, dist if Date.now() - lastChange[src] > 1000
            lastChange[src] = Date.now()
    catch e
        console.log "Error watching #{src}", e
    
build = ->
    if not fs.existsSync(DIST_BASE)
            fs.mkdirSync(DIST_BASE)
        handleMedia(copyFile)
        handleCoffeeFiles(compileCoffee)
        handleLessFiles(compileLess)

compressScripts = ->
    fs.readdir(JS_DIST, (err, files) ->
        for file in files
            file = "#{JS_DIST}/#{file}"
            exec("uglifyjs -o #{file} #{file}")
    )

compressStyles = ->
    fs.readdir(CSS_DIST, (err, files) ->
        for file in files
            file = "#{CSS_DIST}/#{file}"
            exec("cleancss -o #{file} #{file}")
    )

task 'sbuild', '', ->
    build()
    fs.unlink("#{DIST_BASE}/paveo_defaults.json")
    fs.unlink("#{DIST_BASE}/security_mode.json")

task 'watch', 'Compile + watch *.coffee and *.less', ->
    handleCoffeeFiles watchCoffee
    handleLessFiles watchLess
    handleMedia watchMedia

task 'compress', 'Compress scripts and css files', ->
    compressScripts()
    compressStyles()

