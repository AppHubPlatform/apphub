#!/usr/bin/env node

var execSync = require('child_process').execSync;
var path = require('path');
var uuid = require('node-uuid');
var mkdirp = require('mkdirp');

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
    var outputZip = path.join(process.cwd(), argv.outputZip);
    var tmpDir = '/tmp/apphub/' + uuid.v4();
    var buildDir = tmpDir + '/build';
    mkdirp.sync(buildDir);

    var options = [
      '--entry-file', argv.entryFile,
      '--dev', argv.dev,
      '--bundle-output', path.join(buildDir, argv.outputFile),
      '--assets-dest', buildDir,
      '--platform', 'ios',
    ];

    var cmds = [
      'react-native bundle ' + options.join(' '),
      'cp ' + plistFile + ' ' + buildDir,
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
