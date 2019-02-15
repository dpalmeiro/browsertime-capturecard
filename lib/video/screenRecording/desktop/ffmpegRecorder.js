'use strict';

const spawn = require('cross-spawn');
const execSync = require('child_process').execSync;
const execa = require('execa');
const log = require('intel').getLogger('browsertime.video');

function buildX11FfmpegArgs({
  display,
  screen = 0,
  framerate = 30,
  origin = '0,0',
  size,
  filePath
}) {
  return [
    '-hide_banner',
    '-video_size',
    '1280x720',
    '-f',
    'dshow',
    '-rtbufsize',
    '100M',
    '-vcodec',
    'h264',
    '-framerate',
    '30',
    '-probesize',
    '1M',
    '-y',
    '-i',
    'video="Live Gamer Portable 2"',
    filePath
  ];
}

function buildRemoteX11FfmpegArgs({
  display,
  screen = 0,
  framerate = 30,
  origin = '0,0',
  size,
  filePath
}) {
  return [
    '192.168.0.7',
    'ffmpeg',
    '-hide_banner',
    '-video_size',
    '1280x720',
    '-f',
    'v4l2',
    '-rtbufsize',
    '100M',
    '-vcodec',
    'h264',
    '-framerate',
    '60',
    '-probesize',
    '1M',
    '-y',
    '-i',
    '/dev/video0',
    '/tmp/output.mp4'
  ];
}

function buildRemoteDirectShowFfmpegArgs({
  display,
  screen = 0,
  framerate = 30,
  origin = '0,0',
  size,
  filePath
}) {
  return [
    '192.168.0.16',
    'ffmpeg',
    '-hide_banner',
    '-video_size',
    '1280x720',
    '-f',
    'dshow',
    '-rtbufsize',
    '100M',
    '-vcodec',
    'h264',
    '-framerate',
    '60',
    '-probesize',
    '1M',
    '-y',
    '-i',
    "video='Live Gamer Portable 2'",
    '-filter:v',
    '"crop=1280:625:0:60"',
    'C:\\Users\\Denis\\Desktop\\output.mp4'
  ];
}

async function startRecording(ffmpegArgs, nice, filePath) {
  async function waitForRecording(readableStream) {
    return new Promise((resolve, reject) => {
      readableStream.on('data', data => {
        log.trace(data.toString());
        if (data.toString().match(/Press \[q] to stop/)) {
          // readableStream.removeAllListeners('data');
          return resolve();
        }
      });
      readableStream.once('error', reject);
    });
  }
  let ffmpegProcess;
  if (nice !== 0) {
    ffmpegArgs.unshift('ffmpeg');
    ffmpegArgs.unshift(`${nice}`);
    ffmpegArgs.unshift('-n');
    ffmpegProcess = execa('nice', ffmpegArgs);
  } else {
    try {
      execSync('ssh 192.168.0.16 taskkill /im ffmpeg.exe /t /f 2> Out-Null');
    } catch (e) {}
    ffmpegProcess = spawn('ssh', ffmpegArgs, {shell: true});
    execSync('ping 127.0.0.1 -n 2 > nul');

    /*
    //For debugging purposes
    ffmpegProcess.stdout.on('data', (data) => {
      console.log(`stdout: ${data}`);
    });

    ffmpegProcess.stderr.on('data', (data) => {
      console.log(`stderr: ${data}`);
    });
    //*/
  }

  // Race to catch if ffmpeg exists early, or if recording has started
  return Promise.race([ffmpegProcess, waitForRecording(ffmpegProcess.stderr)])
    .then(() => {
      log.debug('Started ffmpeg with ' + ffmpegArgs.join(' '));

      return {
        filePath,
        ffmpegProcess
      };
    })
    .catch(e => {
      throw e;
    });
}

module.exports = {
  /**
   * @returns A promise for a recording object. Pass it to stopRecording.
   */
  async startRecordingX11({
    display,
    origin,
    size,
    filePath,
    offset,
    framerate,
    crf,
    nice
  }) {
    const widthAndHeight = size.split('x');
    const withoutTopBar =
      parseInt(widthAndHeight[0]) -
      offset.x +
      'x' +
      (parseInt(widthAndHeight[1]) - offset.y);

    const ffmpegArgs = buildRemoteDirectShowFfmpegArgs({
      display,
      origin,
      size: withoutTopBar,
      filePath,
      framerate,
     crf
    });
    return startRecording(ffmpegArgs, nice, filePath);
  },
  /**
   * @returns A promise for a recording result, with a filePath property.
   */
  async stopRecording(recording) {
    return Promise.resolve(recording).then(rec => {
      const process = rec.ffmpegProcess;
      delete rec.ffmpegProcess;
      process.stdin.write('q');
      return Promise.resolve(process).then(() => {
        log.debug('Stopped ffmpeg');
        return rec;
      });
    });
  }
};
