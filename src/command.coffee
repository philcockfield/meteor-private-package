fs        = require 'fs'
path      = require 'path'
program   = require 'commander'
SmartRef  = require './smart_ref'

ROOT_PATH = process.env.PWD

# Setup initial conditions.
package = JSON.parse fs.readFileSync path.resolve __dirname, '../package.json'
program
  .version(package.version)

# Define commands
program
  .command('copy')
  .description('Copies package references defined in [smart.ref] file to the [.packages_ref] folder and updates the [smart.json] file.')
  .action ->
    new SmartRef().copy()

program
  .command('link')
  .description('Links package references defined in [smart.ref] file to the [.packages_ref] folder and updates the [smart.json] file.')
  .action ->
    new SmartRef().link()

program
  .command('unlink')
  .description('Unlinks package references defined in [smart.ref] file to the [.packages_ref] folder and updates the [smart.json] file.')
  .action ->
    new SmartRef().unlink()


program
  .command('reset')
  .description('Deletes the [.packages_ref] folder.')
  .action ->
    new SmartRef().reset()



# Finish up.
program.parse process.argv
