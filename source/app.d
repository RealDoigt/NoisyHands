import raylib_misc;
import std.string;

enum maxSound = 5,
     minSound = 0,
     memSize  = 250,
     noisePath = "noise/%s.mp3";

AudioDevice audio;
Snd[] noises;

ubyte memoryPointer,
      sound,
      registerA,
      registerB;
        
auto volume = 0f;
        
ubyte[memSize] memory;

const glyphs = 
[  
  '👋', // play
  '✋', // end if/repeat
  '👌', // repeat
  '✌', // store to volume
  '🤘', // store to sound type
  '👈', // move + 1
  '👉', // move - 1
  '👆', // increment
  '👇', // decrement
  '👍', // higher than
  '👎', // lower than
  '✊', // store to register a
  '👊', // store to register b
  '🤛', // from register a
  '🤜'  // from register b
];

void main(string[] args)
{
    audio = AudioDevice.getInstance;
    
    noises = 
    [
        new Snd(noisePath.format("clap")),
        new Snd(noisePath.format("click")),
        new Snd(noisePath.format("crack")),
        new Snd(noisePath.format("punch")),
        new Snd(noisePath.format("scratch")),
        new Snd(noisePath.format("slap"))
    ];
}
