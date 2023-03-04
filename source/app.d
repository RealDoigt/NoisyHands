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

AudioDevice audio;
    
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
            new Action (()
            {
                audio.setVolume(volume);
                noises[sound].play;
            })
        );
        break;

      case '✋':
        return IndexedStack(i, stack);

      case '👌':
        
        auto max = memory[memoryPointer],
             repeatStack = parse(src, i);
             
        i = repeatStack.i;
        
        stack.add
        (
            new Action(()
            {
                for (size_t j = 0; j < max; ++j)
                    repeatStack.s.execute;
            })
        );
        continue;

      case '✌':
        
        stack.add(new Action(() => volume = memory[memoryPointer] / 255f));
        break;

      case '🤘':
        
        stack.add(new Action(() => sound = memory[memoryPointer]));
        break;

      case '👈':
        
        stack.add(new Action(() => memoryPointer = memoryPointer - 1 < 0 ? memSize - 1 : memoryPointer - 1));
        break;

      case '👉':
        
        stack.add(new Action(() => memoryPointer = memoryPointer + 1 > memSize ? 0 : memoryPointer + 1));
        break;

      case '👆':
        
        stack.add(new Action(() => ++memory[memoryPointer]));
        break;

      case '👇':
        
        stack.add(new Action(() => --memory[memoryPointer]));
        break;

      case '👍':
        
        auto greaterStack = parse(src, i);
        i = greaterStack.i;
        
        stack.add
        (
            new Action(()
            {
                if (registerA > registerB)
                    greaterStack.s.execute;
            })
        );
        continue;

      case '👎':
      
        auto lowerStack = parse(src, i);
        i = lowerStack.i;
        
        stack.add
        (
            new Action(()
            {
                if (registerA < registerB)
                    lowerStack.s.execute;
            })
        );
        continue;

      case '✊':
        
        stack.add(new Action(() => registerA = memory[memoryPointer]));
        break;

      case '👊':
        
        stack.add(new Action(() => registerB = memory[memoryPointer]));
        break;

      case '🤛':
        
        stack.add(new Action(() => memory[memoryPointer] = registerA));
        break;

      case '🤜':
        
        stack.add(new Action(() => memory[memoryPointer] = registerB));
        break;
        
      default: break; // it's there because it's required.
    }
    
    ++i;
  }
  
  return IndexedStack(i, stack);
}

void main(string[] args)
{
    audio = AudioDevice.getInstance;
}
