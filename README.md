# Meteor Private Smart Package Helper

This CLI tool for [Meteor](http://meteor.com/)/[Meteorite](http://oortcloud.github.com/meteorite/)
helps when working with a set of private smart-packages
that you wish to deploy to a cloud service
(such as [Heroku](https://github.com/oortcloud/heroku-buildpack-meteorite))
but you do not want to open-source the packages and host them
on [Atmosphere](https://atmosphere.meteor.com/).

It works by allowing you to reference your local packages as symbolic links during development.
Then when it comes time to deploy, copy all of your private packages locally to the
project, getting you ready to push the complete set of files to Heroku.


## Install

Clone the repo, then add it to your global NPM toolset via.
This will give you access to the `ref` command from the terminal:

    npm install -g meteor-private-package


## Usage

Start by creating adding a `private` element to your Meteorite's `smart.json`.
This provides the file references to your local smart packages that are private:

    {
      "meteor": {
        "git": "https://github.com/meteor/meteor.git",
        "branch": "master"
      },
      "packages": { },
      "private": {
        "base": "../../packages",
        "packages": {
          "core-users": "core-users"
        }
      }
    }

The `base` attribute is optional.  You can either specify the full working path
in each private `package`, or you can set a common path to the directory containing
all your packages.

To switch Meteorite to use these reference as symbolic links:

    $ mrt-ref link

This will update the `smart.json` file.  Then when it comes time to deploy, switch to a new branch
and copy in the packages (using `mrtref copy`), then `push` to your favorite cloud service:

    $ git checkout -b 'deploy'
    $ mrtref copy

    $ git add .
    $ git commit -m 'Ready to deploy!'
    $ git push heroku deploy:master

This will make a copy of the packages to a hidden folder (`.packages.copy`) and update the `smart.json` file
with references these local copies, not the source location of your packages.

After deploying, switch back to your development branch, and your back in business.


## Commands

Set up the Meteorite `smart.json` file with file references declared
within your `private/packages` element (see above):

    $ mrtref link

Copy referenced packages in locally to your project (see the `.packages.copy` folder):

    $ mrtref copy

Removes copied references, (deleting the `.packages.copy` folder):

    $ mrtref reset


