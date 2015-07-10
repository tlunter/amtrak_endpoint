var gulp = require('gulp');
var less = require('gulp-less');
var concat = require('gulp-concat');

gulp.task('less', function() {
  gulp.src('assets/**/*.less')
    .pipe(concat('style.css'))
    .pipe(less())
    .pipe(gulp.dest('./public/'));
});

gulp.task('default', ['less']);

gulp.task('watch', function() {
  gulp.watch('assets/**/*', ['default']);
});
