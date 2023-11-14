import raylib_misc;
import std.string;
import std.array;
import std.stdio;
import std.conv;
import std.uni;

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
        
auto volume = 0f, debugging = false;
        
ubyte[memSize] memory;

/*
  "👋", /+ play                  +/
  "✋", /+ end if/repeat/comment +/
  "👌", /+ repeat                +/
  "✌", /+ store to volume       +/
  "🤘", /+ store to sound type   +/
  "👈", /+ move + 1              +/
  "👉", /+ move - 1              +/
  "👆", /+ increment             +/
  "👇", /+ decrement             +/
  "👍", /+ a higher than b       +/
  "👎", /+ a lower than b        +/
  "✊", /+ store to register a   +/
  "👊", /+ store to register b   +/
  "🫲", /+ from register a       +/
  "🫱", /+ from register b       +/
  "🤌", /+ comment               +/
  "🖕", /+ break from repeat     +/
  "🤏", /+ next iteration        +/
  "🪬", /+ log all values        +/
*/

void read(string src)
{
    // originIndices is a stacks of indices where the interpret has to return to for when one or more repeats are in use
    auto gsrc = src.byGrapheme.array, originIndices = [], currentBlock = 0;
    
    for (size_t i, line = 1, column = 1; i < gsrc.length; ++i, ++column)
    {
        auto current = gsrc[i].array.byCodePoint.text;
        
        switch (current)
        {
            case " ": continue;
            
            case "\n":
                column = 0;
                ++line;
                break;
                
            case "👋": 
            writeln("Reached here"); 
            break;
            
            default:
                if (debugging) 
                    "Unrecognised glyph at line %d and column %d: %s".format(line, column, current).writeln;
            break;
        }
    }
}

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
    
    read("👋");
}
