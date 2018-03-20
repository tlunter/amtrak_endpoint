var gulp = require('gulp');
var less = require('gulp-less');
var concat = require('gulp-concat');

gulp.task('less', function() {
  gulp.src('assets/less/**/*.less')
    .pipe(concat('style.css'))
    .pipe(less())
    .pipe(gulp.dest('./public/'));
});

gulp.task('htmlxml', function() {
  gulp.src(['assets/html/**/*.html', 'assets/xml/**/*.xml'])
    .pipe(gulp.dest('./public/'));
});

gulp.task('default', ['less', 'htmlxml']);

gulp.task('watch', function() {
  gulp.watch('assets/**/*', ['default']);
});
