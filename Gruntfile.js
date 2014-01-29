module.exports = function (grunt) {

  'use strict';

  // Project configuration.
  grunt.initConfig({

    pkg: grunt.file.readJSON('package.json'),
    less: {
      production: {
        options: {
          compress: true
        },
        files: {
          'public/css/style.css': 'public/css/style.less'
        }
      }
    },
    uglify: {
      production: {
        files: {
          'public/scripts/main.min.js': 'public/scripts/main.js'
        }
      }
    },
    watch: {
      less: {
        files: ['**/*.less'],
        tasks: ['less']
      },
      uglify: {
        files: ['public/scripts/main.js'],
        tasks: ['uglify']
      }
    }
  });

  // Load tasks.

  grunt.loadNpmTasks('grunt-contrib-uglify');
  grunt.loadNpmTasks('grunt-contrib-less');
  grunt.loadNpmTasks('grunt-contrib-watch');

  // Task definition.
  grunt.registerTask('default', ['less', 'uglify']);

};