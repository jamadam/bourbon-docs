gulp = require "gulp"
browserSync = require "browser-sync"
sass = require "gulp-ruby-sass"
sassdoc = require "gulp-sassdoc"
coffee = require "gulp-coffee"
prefix = require "gulp-autoprefixer"
shell = require "gulp-shell"
gutil = require "gulp-util"
deploy = require "gulp-gh-pages"
minifyHTML = require "gulp-minify-html"
runSequence = require "run-sequence"

bourbonDocs = require "./package.json"
version = bourbonDocs.version.replace(/\./g, "-")

gulp.task "default", ["develop"]
gulp.task "develop", ["browser-sync", "watch"]
gulp.task "minify", ["minify-html"]
gulp.task "update-docs", ["generate", "minify"]

gulp.task "build", ->
  runSequence "generate", "minify"

gulp.task "all-the-things", ->
  runSequence "update", "build", "deploy"

gulp.task "watch", ->
  gulp.watch "theme/source/sass/*.scss", ["sass"]
  gulp.watch "bourbon/**/*.scss", ["sassdoc"]
  gulp.watch "theme/source/coffeescript/*.coffee", ["coffee"]
  gulp.watch "theme/views/**/*.swig", ["sassdoc"]
  gulp.watch "docs/**/*.html", -> browserSync.reload()

gulp.task "sass", ->
  gulp.src("theme/source/sass/*.scss")
    .pipe sass(bundleExec: true, style: "compressed")
    .on "error", (error) -> gutil.log(error.message)
    .pipe prefix(["last 15 versions", "> 1%", "ie 9"], cascade: true)
    .pipe gulp.dest("theme/assets/css")
    .pipe gulp.dest("docs/latest/assets/css")
    .pipe browserSync.reload(stream: true)

gulp.task "coffee", ->
  gulp.src("theme/source/coffeescript/*.coffee")
    .pipe coffee bare: true
    .on "error", (error) -> gutil.log(error.message)
    .pipe gulp.dest("theme/assets/js")
    .pipe gulp.dest("docs/latest/assets/js")
    .pipe browserSync.reload(stream: true)

gulp.task "update", shell.task("bundle update bourbon && bundle exec bourbon update")

gulp.task "sassdoc", ->
  gulp.src "./bourbon"
    .pipe sassdoc
      dest: "./docs/latest/"
      theme: "theme"
      config: "./theme/view.json"

gulp.task "browser-sync", ["sass", "coffee"], ->
  browserSync.init null,
    server:
      baseDir: "docs"
    host: "localhost"
    open: false

gulp.task "minify-html", ->
  gulp.src "./docs/**/*.html"
    .pipe minifyHTML()
    .pipe gulp.dest "./docs/"

gulp.task "generate", ["sass", "coffee", "sassdoc"], ->
  gulp.src "./docs/latest/**/*"
    .pipe gulp.dest "./docs/#{version}/"

gulp.task "deploy", ->
  gulp.src "./docs/**/*"
    .pipe deploy()
