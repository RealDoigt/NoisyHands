import raylib_misc;
import std.string;

interface IExecutable
{
    void execute();
}

class Action : IExecutable
{
    private void delegate() action;
    
    this (void delegate() action)
    {
        this.action = action;
    }
    
    override void execute()
    {
        action();
    }
}

class Stack : IExecutable
{
    private IExecutable[] actions;
    
    override void execute()
    {
        foreach (a; actions) a.execute;
    }
    
    void add(IExecutable action)
    {
        actions ~= action;
    }
}

struct IndexedStack
{
    int i;
    Stack s;
}

enum maxSound = 5,
     minSound = 0,
     memSize  = 250,
     noisePath = "noise/%s.mp3";

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
          sound,
          registerA,
          registerB;
          
    auto volume = 0f;
          
    ubyte[memSize] memory;
    alias currentMem = memory[memoryPointer];

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

auto parse (wstring src, int i = 0)
{

  Stack stack = new Stack();

  while (i < src.length) 
  {
    switch (src[i]) 
    {
      case '👋':
      
        stack.add
        (
            new Action
            (() => (){
                audio.setVolume(volume);
                noises[sound].play;
            })
        );
        break;

      case '✋':
        return IndexedStack(i, stack);

      case '👌':
        
        auto max = currentMem,
             repeatStack = parse(src, i);
             
        i = repeatStack.i;
        
        stack.add
        (
            new Action
            (() => (){
                for (size_t j = 0; j < max; ++j)
                    repeatStack.stack.execute;
            })
        );
        continue;

      case '✌':
        
        stack.add(new Action(() => volume = currentMem / 255f));
        break;

      case '🤘':
        
        stack.add(() => registers.setSound(memory[registers.memoryPointer]));
        break;

      case '👈':
        
        stack.add(() => registers.setregisters.memoryPointer(registers.memoryPointer - 1));
        break;

      case '👉':
        
        stack.add(() => registers.setregisters.memoryPointer(registers.memoryPointer + 1));
        break;

      case '👆':
        
        stack.add(() => ++memory[memoryPointer]);
        break;

      case '👇':
        
        stack.add(() => --memory[memoryPointer]);
        break;

      case '👍':
        
        const greaterStack = parse(src, i);
        i = greaterStack.index;
        
        stack.push(() => {
                  
          if (registers.a > registers.b)
              greaterStack.stack.forEach(exp => exp());
        });
        continue;

      case '👎':
      
        const lowerStack = parse(src, i);
        i = lowerStack.index;
        
        stack.push(() => {
                  
          if (registers.a < registers.b)
              lowerStack.stack.forEach(exp => exp());
        });
        continue;

      case '✊':
        
        stack.push(() => registers.a = memory[registers.memoryPointer]);
        break;

      case '👊':
        
        stack.push(() => registers.b = memory[registers.memoryPointer]);
        break;

      case '🤛':
        
        stack.push(() => memory[registers.memoryPointer] = registers.a);
        break;

      case '🤜':
        
        stack.push(() => memory[registers.memoryPointer] = registers.b);
        break;
        
      default:
        console.log(chars[i]);
    }
    
    ++i;
  }
  
  return IndexedStack(i, stack);
}

void main(string[] args)
{
    
}
