gulp = require "gulp"
util = require "gulp-util"
notify = require "gulp-notify"
_if = require "gulp-if"

# Paths
# =====
paths =
  scripts:
    src: "./src/*.coffee"
    dest: "./app"
  tests:
    src: "./tests/*.coffee"

# Test
# ====
gulp.task "test", ->
  jasmine = require "gulp-jasmine"

  return gulp.src(paths.tests.src).pipe jasmine()

# Scripts
# =======
gulp.task "scripts", ->
  coffeelint = require "gulp-coffeelint"
  reporter = require("coffeelint-stylish").reporter
  coffee = require "gulp-coffee"
  uglify = require "gulp-uglify"

  # Server
  gulp.src paths.scripts.src
    .pipe do coffeelint
    .pipe do coffeelint.reporter
    .pipe do coffee
    .pipe gulp.dest paths.scripts.dest
    .pipe( _if(process.platform is "darwin", notify("Built <%= file.relative %>")))

# Build
# =====
gulp.task "build", ["scripts"], ->
  util.log "🔨  Built"

# Default
# =======
gulp.task "default", ["build"], ->
  util.log "👓  Watching..."
  gulp.watch [paths.scripts.src], ["scripts"]
  gulp.watch [paths.tests.src], ["test"]
