import raylib_misc;
import std.string;

enum noisePath = "noise/%s.mp3";

const glyphs = 
[  
  "👋", // play
  "🤏", // store to duration
  "✋", // end if/repeat
  "👌", // repeat
  "✌", // store to volume
  "🤘", // store to sound type
  "👈", // move + 1
  "👉", // move - 1
  "👆", // increment
  "👇", // decrement
  "👍", // higher than
  "👎", // lower than
  "✊", // store to register a
  "👊", // store to register b
  "🤛", // from register a
  "🤜"  // from register b
];

auto parse (wstring src, int i = 0)
{

  auto stack = [];  
  dchar[] chars = src.split;

  for (; i < chars.length; ++i) {
  
    switch (chars[i]) {
      
      case "👋":
        
        stack.push(() => {
          
          sounds[registers.sound].volume = /*registers.getVolume()*/ 0.5;
          sounds[registers.sound].play();
        });
        break;

      case "✋":
        return {stack: stack, index: i};

      case "👌":
        
        const repeatStack = parse(src, i);
        i = repeatStack.index;
        
        stack.push(() => {
        
          const max = memory[registers.memoryPointer];
          
          for (let j = 0; j < max; ++j)
              repeatStack.stack.forEach(exp => exp());
        });
        continue;

      case "✌":
        
        stack.push(() => registers.setVolume(memory[registers.memoryPointer]));
        break;

      case "🤘":
        
        stack.push(() => registers.setSound(memory[registers.memoryPointer]));
        break;

      case "👈":
        
        stack.push(() => registers.setregisters.memoryPointer(registers.memoryPointer - 1));
        break;

      case "👉":
        
        stack.push(() => registers.setregisters.memoryPointer(registers.memoryPointer + 1));
        break;

      case "👆":
        
        stack.push(() => ++memory[registers.memoryPointer]);
        break;

      case "👇":
        
        stack.push(() => --memory[registers.memoryPointer]);
        break;

      case "👍":
        
        const greaterStack = parse(src, i);
        i = greaterStack.index;
        
        stack.push(() => {
                  
          if (registers.a > registers.b)
              greaterStack.stack.forEach(exp => exp());
        });
        continue;

      case "👎":
      
        const lowerStack = parse(src, i);
        i = lowerStack.index;
        
        stack.push(() => {
                  
          if (registers.a < registers.b)
              lowerStack.stack.forEach(exp => exp());
        });
        continue;

      case "✊":
        
        stack.push(() => registers.a = memory[registers.memoryPointer]);
        break;

      case "👊":
        
        stack.push(() => registers.b = memory[registers.memoryPointer]);
        break;

      case "🤛":
        
        stack.push(() => memory[registers.memoryPointer] = registers.a);
        break;

      case "🤜":
        
        stack.push(() => memory[registers.memoryPointer] = registers.b);
        break;
        
      default:
        console.log(chars[i]);
    }
  }
  
  return {stack: stack, index: i};
}

void main(string[] args)
{
    auto audio = AudioDevice.getInstance;
    
    auto noises = 
    [
        new Snd(noisePath.format("clap")),
        new Snd(noisePath.format("click")),
        new Snd(noisePath.format("crack")),
        new Snd(noisePath.format("punch")),
        new Snd(noisePath.format("scratch")),
        new Snd(noisePath.format("slap"))
    ];
    
    ubyte memoryPointer,
          duration,
          volume,
          sound,
          registerA,
          registerB;
          
    const maxSound = 5,
          minSound = 0,
          memSize  = 250;
          
    ubyte[memSize] memory;
}
