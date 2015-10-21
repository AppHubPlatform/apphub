/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */
'use strict';

jest
  .autoMockOff()
  .mock('../../Cache')
  .mock('../../Activity');

const Promise = require('promise');
const path = require('path');

jest.mock('fs');

var BundlesLayout = require('../index');
var Cache = require('../../Cache');
var DependencyResolver = require('../../DependencyResolver');
var fs = require('fs');

describe('BundlesLayout', () => {
  var fileWatcher;

  const polyfills = [
    'polyfills/prelude_dev.js',
    'polyfills/prelude.js',
    'polyfills/require.js',
    'polyfills/polyfills.js',
    'polyfills/console.js',
    'polyfills/error-guard.js',
    'polyfills/String.prototype.es6.js',
    'polyfills/Array.prototype.es6.js',
  ];
  const baseFs = getBaseFs();

  beforeEach(() => {
    fileWatcher = {
      on: () => this,
      isWatchman: () => Promise.resolve(false)
    };
  });

  describe('generate', () => {
    function newBundlesLayout() {
      const resolver = new DependencyResolver({
        projectRoots: ['/root', '/' + __dirname.split('/')[1]],
        fileWatcher: fileWatcher,
        cache: new Cache(),
        assetExts: ['js', 'png'],
        assetRoots: ['/root'],
      });

      return new BundlesLayout({
        dependencyResolver: resolver,
        resetCache: true,
        projectRoots: ['/root', '/' + __dirname.split('/')[1]],
      });
    }

    function stripPolyfills(bundle) {
      return Promise
        .all(bundle.children.map(childModule => stripPolyfills(childModule)))
        .then(children => {
          const modules = bundle.modules
            .filter(moduleName => { // filter polyfills
              for (let p of polyfills) {
                if (moduleName.indexOf(p) !== -1) {
                  return false;
                }
              }
              return true;
            });

          return {
            id: bundle.id,
            modules: modules,
            children: children,
          };
        });
    }

    function setMockFilesystem(mockFs) {
      fs.__setMockFilesystem(Object.assign(mockFs, baseFs));
    }

    pit('should bundle single-module app', () => {
      setMockFilesystem({
        'root': {
          'index.js': `
            /**
             * @providesModule index
             */`,
        }
      });

      return newBundlesLayout().getLayout('/root/index.js').then(bundles =>
        stripPolyfills(bundles).then(resolvedBundles =>
          expect(resolvedBundles).toEqual({
            id: 'bundle.0',
            modules: ['/root/index.js'],
            children: [],
          })
        )
      );
    });

    pit('should bundle dependant modules', () => {
      setMockFilesystem({
        'root': {
          'index.js': `
            /**
             * @providesModule index
             */
            require("a");`,
          'a.js': `
            /**
             * @providesModule a
             */`,
        }
      });

      return newBundlesLayout().getLayout('/root/index.js').then(bundles =>
        stripPolyfills(bundles).then(resolvedBundles =>
          expect(resolvedBundles).toEqual({
            id: 'bundle.0',
            modules: ['/root/index.js', '/root/a.js'],
            children: [],
          })
        )
      );
    });

    pit('should split bundles for async dependencies', () => {
      setMockFilesystem({
        'root': {
          'index.js': `
            /**
             * @providesModule index
             */
            System.import("a");`,
          'a.js': `
            /**,
             * @providesModule a
             */`,
        }
      });

      return newBundlesLayout().getLayout('/root/index.js').then(bundles =>
        stripPolyfills(bundles).then(resolvedBundles =>
          expect(resolvedBundles).toEqual({
            id: 'bundle.0',
            modules: ['/root/index.js'],
            children: [{
              id: 'bundle.0.1',
              modules: ['/root/a.js'],
              children: [],
            }],
          })
        )
      );
    });

    pit('should split into multiple bundles separate async dependencies', () => {
      setMockFilesystem({
        'root': {
          'index.js': `
            /**
             * @providesModule index
             */
            System.import("a");
            System.import("b");`,
          'a.js': `
            /**,
             * @providesModule a
             */`,
          'b.js': `
            /**
             * @providesModule b
             */`,
        }
      });

      return newBundlesLayout().getLayout('/root/index.js').then(bundles =>
        stripPolyfills(bundles).then(resolvedBundles =>
          expect(resolvedBundles).toEqual({
            id: 'bundle.0',
            modules: ['/root/index.js'],
            children: [
              {
                id: 'bundle.0.1',
                modules: ['/root/a.js'],
                children: [],
              }, {
                id: 'bundle.0.2',
                modules: ['/root/b.js'],
                children: [],
              },
            ],
          })
        )
      );
    });

    pit('should fully traverse sync dependencies', () => {
      setMockFilesystem({
        'root': {
          'index.js': `
            /**
             * @providesModule index
             */
            require("a");
            System.import("b");`,
          'a.js': `
            /**,
             * @providesModule a
             */`,
          'b.js': `
            /**
             * @providesModule b
             */`,
        }
      });

      return newBundlesLayout().getLayout('/root/index.js').then(bundles =>
        stripPolyfills(bundles).then(resolvedBundles =>
          expect(resolvedBundles).toEqual({
            id: 'bundle.0',
            modules: ['/root/index.js', '/root/a.js'],
            children: [{
              id: 'bundle.0.1',
              modules: ['/root/b.js'],
              children: [],
            }],
          })
        )
      );
    });

    pit('should include sync dependencies async dependencies might have', () => {
      setMockFilesystem({
        'root': {
          'index.js': `
            /**
             * @providesModule index
             */
            System.import("a");`,
          'a.js': `
            /**,
             * @providesModule a
             */,
            require("b");`,
          'b.js': `
            /**
             * @providesModule b
             */
            require("c");`,
          'c.js': `
            /**
             * @providesModule c
             */`,
        }
      });

      return newBundlesLayout().getLayout('/root/index.js').then(bundles =>
        stripPolyfills(bundles).then(resolvedBundles =>
          expect(resolvedBundles).toEqual({
            id: 'bundle.0',
            modules: ['/root/index.js'],
            children: [{
              id: 'bundle.0.1',
              modules: ['/root/a.js', '/root/b.js', '/root/c.js'],
              children: [],
            }],
          })
        )
      );
    });

    pit('should allow duplicated dependencies across bundles', () => {
      setMockFilesystem({
        'root': {
          'index.js': `
            /**
             * @providesModule index
             */
            System.import("a");
            System.import("b");`,
          'a.js': `
            /**,
             * @providesModule a
             */,
            require("c");`,
          'b.js': `
            /**
             * @providesModule b
             */
            require("c");`,
          'c.js': `
            /**
             * @providesModule c
             */`,
        }
      });

      return newBundlesLayout().getLayout('/root/index.js').then(bundles =>
        stripPolyfills(bundles).then(resolvedBundles =>
          expect(resolvedBundles).toEqual({
            id: 'bundle.0',
            modules: ['/root/index.js'],
            children: [
              {
                id: 'bundle.0.1',
                modules: ['/root/a.js', '/root/c.js'],
                children: [],
              },
              {
                id: 'bundle.0.2',
                modules: ['/root/b.js', '/root/c.js'],
                children: [],
              },
            ],
          })
        )
      );
    });

    pit('should put in separate bundles async dependencies of async dependencies', () => {
      setMockFilesystem({
        'root': {
          'index.js': `
            /**
             * @providesModule index
             */
            System.import("a");`,
          'a.js': `
            /**,
             * @providesModule a
             */,
            System.import("b");`,
          'b.js': `
            /**
             * @providesModule b
             */
            require("c");`,
          'c.js': `
            /**
             * @providesModule c
             */`,
        }
      });

      return newBundlesLayout().getLayout('/root/index.js').then(bundles =>
        stripPolyfills(bundles).then(resolvedBundles =>
          expect(resolvedBundles).toEqual({
            id: 'bundle.0',
            modules: ['/root/index.js'],
            children: [
              {
                id: 'bundle.0.1',
                modules: ['/root/a.js'],
                children: [{
                  id: 'bundle.0.1.2',
                  modules: ['/root/b.js', '/root/c.js'],
                  children: [],
                }],
              },
            ],
          })
        )
      );
    });

    pit('should put image dependencies into separate bundles', () => {
      setMockFilesystem({
        'root': {
          'index.js': `
            /**
             * @providesModule index
             */
            System.import("a");`,
          'a.js':`
            /**,
             * @providesModule a
             */,
            require("./img.png");`,
          'img.png': '',
        }
      });

      return newBundlesLayout().getLayout('/root/index.js').then(bundles =>
        stripPolyfills(bundles).then(resolvedBundles =>
          expect(resolvedBundles).toEqual({
            id: 'bundle.0',
            modules: ['/root/index.js'],
            children: [{
              id: 'bundle.0.1',
              modules: ['/root/a.js', '/root/img.png'],
              children: [],
            }],
          })
        )
      );
    });

    pit('should put image dependencies across bundles', () => {
      setMockFilesystem({
        'root': {
          'index.js': `
            /**
             * @providesModule index
             */
            System.import("a");
            System.import("b");`,
          'a.js':`
            /**,
             * @providesModule a
             */,
            require("./img.png");`,
          'b.js':`
            /**,
             * @providesModule b
             */,
            require("./img.png");`,
          'img.png': '',
        }
      });

      return newBundlesLayout().getLayout('/root/index.js').then(bundles =>
        stripPolyfills(bundles).then(resolvedBundles =>
          expect(resolvedBundles).toEqual({
            id: 'bundle.0',
            modules: ['/root/index.js'],
            children: [
              {
                id: 'bundle.0.1',
                modules: ['/root/a.js', '/root/img.png'],
                children: [],
              },
              {
                id: 'bundle.0.2',
                modules: ['/root/b.js', '/root/img.png'],
                children: [],
              },
            ],
          })
        )
      );
    });

    pit('could async require asset', () => {
      setMockFilesystem({
        'root': {
          'index.js': `
            /**
             * @providesModule index
             */
            System.import("./img.png");`,
          'img.png': '',
        }
      });

      return newBundlesLayout().getLayout('/root/index.js').then(bundles =>
        stripPolyfills(bundles).then(resolvedBundles =>
          expect(resolvedBundles).toEqual({
            id: 'bundle.0',
            modules: ['/root/index.js'],
            children: [{
              id: 'bundle.0.1',
              modules: ['/root/img.png'],
              children: [],
            }],
          })
        )
      );
    });

    pit('should include deprecated assets into separate bundles', () => {
      setMockFilesystem({
        'root': {
          'index.js': `
            /**
             * @providesModule index
             */
            System.import("a");`,
          'a.js':`
            /**,
             * @providesModule a
             */,
            require("image!img");`,
          'img.png': '',
        }
      });

      return newBundlesLayout().getLayout('/root/index.js').then(bundles =>
        stripPolyfills(bundles).then(resolvedBundles =>
          expect(resolvedBundles).toEqual({
            id: 'bundle.0',
            modules: ['/root/index.js'],
            children: [{
              id: 'bundle.0.1',
              modules: ['/root/a.js', '/root/img.png'],
              children: [],
            }],
          })
        )
      );
    });

    pit('could async require deprecated asset', () => {
      setMockFilesystem({
        'root': {
          'index.js': `
            /**
             * @providesModule index
             */
            System.import("image!img");`,
          'img.png': '',
        }
      });

      return newBundlesLayout().getLayout('/root/index.js').then(bundles =>
        stripPolyfills(bundles).then(resolvedBundles =>
          expect(resolvedBundles).toEqual({
            id: 'bundle.0',
            modules: ['/root/index.js'],
            children: [{
              id: 'bundle.0.1',
              modules: ['/root/img.png'],
              children: [],
            }],
          })
        )
      );
    });

    pit('should put packages into bundles', () => {
      setMockFilesystem({
        'root': {
          'index.js': `
            /**
             * @providesModule index
             */
            System.import("aPackage");`,
          'aPackage': {
            'package.json': JSON.stringify({
              name: 'aPackage',
              main: './main.js',
              browser: {
                './main.js': './client.js',
              },
            }),
            'main.js': 'some other code',
            'client.js': 'some code',
          },
        }
      });

      return newBundlesLayout().getLayout('/root/index.js').then(bundles =>
        stripPolyfills(bundles).then(resolvedBundles =>
          expect(resolvedBundles).toEqual({
            id: 'bundle.0',
            modules: ['/root/index.js'],
            children: [{
              id: 'bundle.0.1',
              modules: ['/root/aPackage/client.js'],
              children: [],
            }],
          })
        )
      );
    });
  });

  function getBaseFs() {
    const p = path.join(__dirname, '../../../DependencyResolver/polyfills').substring(1);
    const root = {};
    let currentPath = root;

    p.split('/').forEach(part => {
      const child = {};
      currentPath[part] = child;
      currentPath = child;
    });

    polyfills.forEach(polyfill =>
      currentPath[polyfill.split('/')[1]] = ''
    );

    return root;
  }
});
