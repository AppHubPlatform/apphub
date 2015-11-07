/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */
'use strict';

const blacklist = require('react-native/packager/blacklist.js');
const path = require('path');

module.exports = {
  getProjectRoots() {
    return [__dirname];
  },

  getAssetRoots() {
    return [path.join(__dirname, 'images')];
  },

  getBlacklistRE(platform) {
    return blacklist(platform);
  },
};