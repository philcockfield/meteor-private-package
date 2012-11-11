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
    @smartRef = @loadJson 'smart.ref'

    @smartJson = @loadJson('smart.json')
    @smartJson?.packages ?= {}



  ###
  Copies the reference packages to the projects internal folder.
  ###
  copy: ->
    return unless @hasRefPackages()
    console.log 'Copying:'.blue
    @reset(true)
    fs.mkdir @packagesPath

    # Copy each package.
    do =>
      for path in @getPaths()
        console.log ' > ', 'Copy'.green, path.name.blue
        console.log '      From:'.grey, path.source
        console.log '      To:  '.grey, path.target
        try
          # Perform the copy.
          wrench.mkdirSyncRecursive path.target, COPY_MODE

          for name in fs.readdirSync(path.source)
            # Ignore known files.
            continue if name is '.DS_Store'
            continue if name is '.meteor'

            sourcePath = "#{path.source}/#{name}"
            targetPath = "#{path.target}/#{name}"

            if fs.statSync(sourcePath).isDirectory()
              wrench.copyDirSyncRecursive sourcePath, targetPath, {}
            else
              copyFile sourcePath, targetPath

        catch error
          console.log '      FAILED'.red, error
        console.log ''

    # Update the smart JSON.
    do =>
      return unless @smartJson?
      for name, path of @smartRef.packages
        @smartJson.packages[name] =
          path: "./#{PACKAGES_DIR}/#{name}"
      @saveSmartJson()


  ###
  Creates a symbolic link for all the reference packages.
  ###
  link: ->
    # Setup initial conditions.
    return unless @hasRefPackages()
    unless @smartJson?
      console.log 'Cannot link. There is no [smart.json] file to update.'.red
      return

    @reset(true)
    console.log 'Linking:'.blue

    for name, path of @smartRef.packages
      console.log ' > ', 'Link'.green, name.blue, ' => '.grey, path
      @smartJson.packages[name] =
        path: path

    # Finish up.
    console.log ''
    @saveSmartJson()



  ###
  Unlinks all referenced packages.
  ###
  unlink: (silent = false) ->
    return unless @hasRefPackages()
    console.log 'Unlinking:'.blue unless silent
    tryUnlink = (path) =>
      try
        path = fsPath.resolve "#{@packagesPath}/#{path}"
        fs.unlinkSync path
        console.log '> ', 'Unlinked:'.green, path unless silent

    if fs.existsSync(@packagesPath)
      for path in fs.readdirSync(@packagesPath)
        tryUnlink path



  reset: (silent = false) ->
    # Attempt to unlink first (to ensure linked files are not deleted),
    @unlink(true)

    # Delete the physical directory.
    if fs.existsSync(@packagesPath)
      wrench.rmdirSyncRecursive @packagesPath

    # Reset the [smart.json] file.
    if @smartJson?
      for name, path of @smartRef.packages
        delete @smartJson.packages[name]
      @saveSmartJson()


  # Utility ================================================================


  getPaths: ->
    result = []
    if @smartRef.packages?
      for name, sourcePath of @smartRef.packages
        result.push
                name:   name
                source: fsPath.resolve sourcePath
                target: fsPath.resolve "#{@packagesPath}/#{fsPath.basename(sourcePath)}"
    result


  hasRefPackages: ->
    return true if @getPaths().length > 0
    console.log 'No packages defined in the [smart.ref] file.'.red
    console.log ''
    false


  loadJson: (file) ->
    path = fsPath.resolve(file)
    JSON.parse fs.readFileSync(path) if fs.existsSync(path)


  saveSmartJson: ->
    jsonString = JSON.stringify(@smartJson, null, 2) + '\n'
    fs.writeFileSync fsPath.resolve('smart.json'), jsonString

