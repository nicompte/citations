module.exports = function (grunt) {

  'use strict';

  // Project configuration.
  grunt.initConfig({

    pkg: grunt.file.readJSON('package.json'),
    less: {
      production: {
        files: {
          'public/css/style.css': 'public/css/style.less'
        }
      }
    },
    watch: {
      less: {
        files: ['**/*.less'],
        tasks: ['less']
      }
    }
  });

  // Load tasks.

  grunt.loadNpmTasks('grunt-contrib-less');
  grunt.loadNpmTasks('grunt-contrib-watch');

  // Task definition.
  grunt.registerTask('default', ['less']);

};