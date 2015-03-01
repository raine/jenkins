Promise = require \bluebird
async   = Promise.coroutine
through = require 'through2'
{cyan}  = require \chalk
{tail}  = require '../api/tail-build'
yargs   = require \yargs

format-line = (build, line) ->
  build-number = cyan "[##{build.number}]"
  "#build-number #line"

format-tail-output = ->
  var cur-build

  through.obj (chunk, enc, cb) ->
    push-line = ~> @push new Buffer "#it\n"

    switch typeof! chunk
      | \String
        push-line format-line cur-build, chunk
      | \Object
        switch chunk.event
        | \GOT_BUILD         => cur-build := chunk.build
        | \WAITING_FOR_BUILD => push-line 'waiting for the next build...'

    cb!

cli-tail = async (argv) ->*
  job-name = argv._.1
  return yargs.show-help! unless job-name

  output = yield tail job-name, argv.build, argv.follow
  output.cata do
    Just: (output) ->
      output
        .pipe format-tail-output!
        .pipe process.stdout
        .on \end process.exit
    Nothing: ->
      str = "unable to find job"
      console.log switch
        | argv.build => "#str or build: #job-name [##{argv.build}]"
        | otherwise  => "#str: #job-name"

module.exports = cli-tail
