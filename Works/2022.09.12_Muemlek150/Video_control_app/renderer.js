//const { spawn } = require('child_process');
//const fs = require('fs');

//let frames;

//frames = fs.readFileSync('src/frames.txt', 'utf-8').split('\n');
let frames = [ "0", "1250", "1550", "2550","3250","3500","4125","4875","5550","6175","6675","7175","7425","7675","8425"];

function send(command, ...args) {
  console.log(`Sending command: ${command} params: ${args}`);
  //if (useNotifications()) {
  //  audioLoad();
  //}
  const path = ['api', command, ...args].join('/');

  const request = new XMLHttpRequest();
  request.open("post", path);

  request.send(null);
  // Kick off a refresh quickly in response to user input.
  //refreshStatus(100);
}


const seekToFrame = (frame) => {

  //const sender = spawn('echo', ['{ "command": ["set_property", "time-pos", ' + frame / 25 + '] }']);

  //const socat = spawn('socat', ['-', '/tmp/mpvsocket'])

  //sender.stdout.on('data', data => {
    //socat.stdin.write(data);
  //})

  // socat.stdout.on('data', (data) => {
  //   console.log(data.toString());
  // })
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
