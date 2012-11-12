_         = require 'underscore'
fs        = require 'fs'
fsPath    = require 'path'
util      = require 'util'
wrench    = require 'wrench'
colors    = require 'colors'


PACKAGES_DIR = '.packages.copy'
COPY_MODE    = 0777

copyFile = (source, target, mode=COPY_MODE) ->
  # Perform the file copy operation.
  reader = fs.createReadStream(source)
  writer = fs.createWriteStream(target, mode:mode)
  util.pump reader, writer, (err) -> callback?(err)


###
Represents a [smart.ref] JSON definition.
###
module.exports = class SmartRef
  constructor: ->
    @packagesPath = fsPath.resolve PACKAGES_DIR

    @json = @loadJson('smart.json')
    @json ?= {}
    @json.packages ?= {}
    @json.private ?= {}
    @json.private.packages ?= {}



  ###
  Copies the reference packages to the projects internal folder.
  ###
  copy: ->
    return unless @hasPrivatePackages()
    console.log 'Copying:'.blue
    @reset(true)
    fs.mkdir @packagesPath

    privatePaths = @privatePaths()
    fnTargetPath = (name) -> "./#{PACKAGES_DIR}/#{name}"

    # Copy each package.
    do =>
      for item in privatePaths
        { name, path } = item

        sourcePath = fsPath.resolve path
        targetPath = fsPath.resolve fnTargetPath(name)

        console.log ' > ', 'Copy'.green, name.blue
        console.log '      From:'.grey, sourcePath
        console.log '      To:  '.grey, targetPath

        try
          # Perform the copy.
          wrench.mkdirSyncRecursive targetPath, COPY_MODE

          for name in fs.readdirSync(sourcePath)
            # Ignore known files.
            continue if name is '.DS_Store'
            continue if name is '.meteor'

            if fs.statSync(sourcePath).isDirectory()
              wrench.copyDirSyncRecursive sourcePath, targetPath, {}
            else
              copyFile sourcePath, targetPath

        catch error
          console.log '      FAILED'.red, error
        console.log ''

    # Update the smart JSON.
    do =>
      for item in privatePaths
        { name, path } = item
        @json.packages[name] =
          path: fnTargetPath(name) # Smart.json now referes to the local copy.
      @saveJson()


  ###
  Creates a symbolic link for all the reference packages.
  ###
  link: ->

    # Setup initial conditions.
    return unless @hasPrivatePackages()
    @reset(true)
    console.log 'Linking:'.blue

    for item in @privatePaths()
      { name, path } = item
      console.log ' > ', 'Link'.green, name.blue, ' => '.grey, path
      @json.packages[name] =
        path: path

    # Finish up.
    console.log ''
    @saveJson()



  ###
  Unlinks all referenced packages.
  ###
  unlink: (silent = false) ->
    return unless @hasPrivatePackages()
    console.log 'Unlinking:'.blue unless silent

    for item in @privatePaths()
      { name, path } = item
      delete @json.packages[name]
      unless silent
        console.log ' > ', 'Unlink'.green, name.blue, ' => '.grey, path

    # Finish up.
    console.log '' unless silent
    @saveJson()



  reset: (silent = false) ->
    # Attempt to unlink first (to ensure linked files are not deleted),
    @unlink(true)

    # Delete the physical directory.
    if fs.existsSync(@packagesPath)
      wrench.rmdirSyncRecursive @packagesPath

    # Reset the [smart.json] file.
    for item of @privatePaths()
      delete @json.packages[item.name]
    @saveJson()

    # Finish up.
    console.log 'Reset'.green unless silent


  # Utility ================================================================


  privatePaths: ->
    # Prepare the base path.
    base = @json.private.base ? ''
    unless base is ''
      base = _(base).rtrim '/'
      base += '/'

    result = []
    for name, path of @json.private.packages
      path = base + path
      result.push
          name:   name
          path:   path
    result


  hasPrivatePackages: ->
    return true if @privatePaths().length > 0
    console.log 'No private packages defined in the [smart.json] file.'.red
    console.log ''
    false


  loadJson: (file) ->
    path = fsPath.resolve(file)
    JSON.parse fs.readFileSync(path) if fs.existsSync(path)


  saveJson: ->
    jsonString = JSON.stringify(@json, null, 2) + '\n'
    fs.writeFileSync fsPath.resolve('smart.json'), jsonString

