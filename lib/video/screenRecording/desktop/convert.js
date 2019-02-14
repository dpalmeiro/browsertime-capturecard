'use strict';

const spawn = require('cross-spawn');
const log = require('intel').getLogger('browsertime.video');

module.exports = async function convert(src, dest, crf) {
  const scriptArgs = [
    '-i',
    src,
    '-codec',
    'copy',
    dest
  ];

  log.debug('Converting video to viewable format with args %j', scriptArgs);

  return spawn('ffmpeg', scriptArgs);
};
