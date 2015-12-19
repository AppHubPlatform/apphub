#!/usr/bin/env node

var execSync = require('child_process').execSync;
var path = require('path');
var uuid = require('node-uuid');
var mkdirp = require('mkdirp');
var plist = require('plist');
var fs = require('fs');

var MANIFEST_VERSION = 'pre1';
var MANIFEST_FILE_NAME = 'rn-bundle-manifest.json';
var PLIST_VERSION_KEY = 'CFBundleShortVersionString';
var IOS_BUILD_PATH = 'ios.bundle';

var argv = require('yargs')
  .usage('apphub <command>')
  .command('build', 'build a zip that can be uploaded to AppHub', function (yargs, argv) {
    argv = yargs
      .option('o', {
        alias: 'output-zip',
        description: 'Output zip relative path',
        required: true,
      })
      .option('entry-file', {
        description: 'Path to the root JS file, either absolute or relative to JS root',
        default: 'index.ios.js',
      })
      .option('output-file', {
        description: 'File name where to store the resulting bundle',
        default: 'main.jsbundle',
      })
      .option('plist-file', {
        description: "Relative location to the project's Info.plist",
      })
      .option('dev',  {
        default: false,
        description: 'If false, warnings are disabled and the bundle is minified'
      })
      .help('help')
      .argv

    var plistFile = argv.plistFile ||
      path.join('ios', require(path.join(process.cwd(), 'package.json')).name, 'Info.plist');
    var plistObj = plist.parse(fs.readFileSync(plistFile, 'utf8'));
    var iosVersion = plistObj[PLIST_VERSION_KEY];
    if (! iosVersion) {
      console.log('Could not read iOS version from plist: ' + plistFile);
      console.log('Specify a plist location with --plist-file <path/to/file>');
      process.exit(0);
    }

    var outputZip = path.join(process.cwd(), argv.outputZip);
    var tmpDir = path.join('tmp', 'apphub', uuid.v4());

    var buildDir = path.join(tmpDir, 'build');
    var iosBuildDir = path.join(buildDir, IOS_BUILD_PATH);
    mkdirp.sync(iosBuildDir);

    var options = [
      '--entry-file', argv.entryFile,
      '--dev', argv.dev,
      '--bundle-output', path.join(iosBuildDir, argv.outputFile),
      '--assets-dest', iosBuildDir,
      '--platform', 'ios',
    ];

    var manifest = {
      manifestVersion: MANIFEST_VERSION,
      bundles: {
        ios: {
          path: IOS_BUILD_PATH,
          binaryVersion: iosVersion,
        },
      }
    };

    fs.writeFileSync(path.join(buildDir, MANIFEST_FILE_NAME),
                     JSON.stringify(manifest, null, 2),
                     'utf-8');

    var cmds = [
      'react-native bundle ' + options.join(' '),
      'cd ' + tmpDir + ' && zip -r ' + outputZip + ' build/',
    ];

    for (var i = 0; i < cmds.length; i++) {
      var cmd = cmds[i];
      console.log(cmd);
      execSync(cmd, { stdio: [0, 1, 2] });
    }
  })
  .help('help')
  .argv;
