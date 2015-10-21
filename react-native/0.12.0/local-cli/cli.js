/**
 * Copyright 2004-present Facebook. All Rights Reserved.
 */

'use strict';

var fs = require('fs');
var spawn = require('child_process').spawn;
var path = require('path');
var generateAndroid = require('./generate-android.js');
var init = require('./init.js');
var install = require('./install.js');
var bundle = require('./bundle.js');
var newLibrary = require('./new-library.js');
var runAndroid = require('./run-android.js');
var runPackager = require('./run-packager.js');

function printUsage() {
  console.log([
    'Usage: react-native <command>',
    '',
    'Commands:',
    '  start: starts the webserver',
    '  install: installs npm react components',
    '  bundle: builds the javascript bundle for offline use',
    '  new-library: generates a native library bridge',
    '  android: generates an Android project for your app'
  ].join('\n'));
  process.exit(1);
}

function printInitWarning() {
  console.log([
    'Looks like React Native project already exists in the current',
    'folder. Run this command from a different folder or remove node_modules/react-native'
  ].join('\n'));
  process.exit(1);
}

function run() {
  var args = process.argv.slice(2);
  if (args.length === 0) {
    printUsage();
  }

  switch (args[0]) {
  case 'start':
    runPackager();
    break;
  case 'install':
    install.init();
    break;
  case 'bundle':
    bundle.init(args);
    break;
  case 'new-library':
    newLibrary.init(args);
    break;
  case 'init':
    printInitWarning();
    break;
  case 'android':
    generateAndroid(
      process.cwd(),
      JSON.parse(fs.readFileSync('package.json', 'utf8')).name
    );
    break;
  case 'run-android':
    runAndroid();
    break;
  default:
    console.error('Command `%s` unrecognized', args[0]);
    printUsage();
  }
  // Here goes any cli commands we need to
}

if (require.main === module) {
  run();
}

module.exports = {
  run: run,
  init: init,
};
