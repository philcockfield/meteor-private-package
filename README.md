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

    $ npm install -g meteor-package-ref


## Usage

Start by creating a `smart.ref` file that complements your Meteorite's `smart.json`.
This provides the file references to your local smart packages:

    {
      "packages": {
        "package1": "../packages/my-package"
      }
    }

To switch the Meteorite file to use these reference as symbolic links:

    $ mrt-ref link

This will update the `smart.json` file.  Then when it comes time to deploy, switch to a new branch
and copy in the packages (using `mrt-ref copy`), then `push` to your favorite cloud service:

    $ git checkout -b 'deploy'
    $ mrt-ref copy

    $ git add .
    $ git commit -m 'Ready to deploy!'
    $ git push heroku deploy:master

This will make a copy of the packages to a hidden folder (`.packages.copy`) and update the `smart.json` file
with references these local copies, not the source location of your packages.

After deploying, switch back to your development branch, and your back in business.





