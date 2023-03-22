const { spawn } = require('child_process');
const fs = require('fs');

let frames;
    DEBUG = false;
    settings = {"disableNotifications": false}
    command = 'set_position'


const seekToFrameOld = (frame) => {

  //const sender = spawn('echo', ['{ "command": ["set_property", "time-pos", ' + frame / 25 + '] }']);

  //const socat = spawn('socat', ['-', '/tmp/mpvsocket'])

  //sender.stdout.on('data', data => {
    //socat.stdin.write(data);
  //})

  // socat.stdout.on('data', (data) => {
  //   console.log(data.toString());
  // })
}

function seekToFrame(frame) {
  frame = frame/25
  DEBUG && console.log(`Sending command: ${command} params: ${frame}`);

  const path = ['api', command, ...frame].join('/');

  const request = new XMLHttpRequest();
  request.open("post", path);

  request.send(null);
  // Kick off a refresh quickly in response to user input.
  // refreshStatus(100);  
}

let buttons = document.querySelectorAll('.button')

buttons.forEach(el => {
  el.addEventListener('click', () => {
    buttons.forEach(ele => {ele.childNodes[1].classList.remove("playing")})
    el.childNodes[1].classList.add("playing")
    const serial = el.dataset.serial;
    const idx = serial - 1;
    const frame = frames[idx]/25;
    if (frame == undefined) {
      throw `${idx} is out of bounds!`;
    }
    console.log(`Seeked to frame ${frame}`)
    send('set_position',frame)
    //seekToFrame(frame)
    setTimeout(() => {
      el.childNodes[1].classList.remove("playing")
    }, 10000);
  })
})

let timer

document.addEventListener('click', (e) => {
  if (timer != undefined) {
    e.stopPropagation()
    e.preventDefault()
    return
  }
  console.log('Clicking is blocked!')
  timer = setTimeout(() => {
    timer = undefined
    console.log('Clicking is allowed!')
  }, 400);
}, true)
