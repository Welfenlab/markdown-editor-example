var gulp        = require('gulp');
var source      = require('vinyl-source-stream');
var browserify  = require('browserify');
var buffer      = require('vinyl-buffer');
var uglify      = require('gulp-uglify');
var sourcemaps  = require('gulp-sourcemaps');

// browserify bundle for direct browser use.
gulp.task("bundle", function(){
  bundler = browserify('./example.coffee',
    {
      transform: ['coffeeify'],
      extensions: ['.coffee'],
      debug: false
    });
  
  return bundler.bundle()
    .pipe(source('example.js'))
    .pipe(buffer())
//    .pipe(sourcemaps.init({loadMaps:true}))
//    .pipe(uglify())
//    .pipe(sourcemaps.write("./"))
    .pipe(gulp.dest('dist'));
});

gulp.task("default", ["bundle"]);
