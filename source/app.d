import door;
import raylib;
import std.string;
import std.array;
import std.stdio;
import std.conv;
import std.uni;

enum memSize   = 250,
     colorPath = "palette.csv",
     noisePath = "noise/%s.mp3";

AudioDevice audio;
Snd[] noises;

ubyte memoryPointer,
      sound, // in drawing mode, this is colour
      registerA,
      registerB;

auto volume    = 0f,
     debugging = false,
     mode      = true; // true == noise making    false == drawing

ubyte[memSize] memory;

/*
  "👋", /+ play/draw             +/
  "✋", /+ end if/repeat/comment +/
  "✍️", /+ change mode           +/
  "👌", /+ repeat                +/
  "✌", /+ store to volume       +/
  "🤘", /+ store to sound type   +/
  "🖖", /+ store to delay        +/
  "🫳", /+ store to current mem  +/
  "👈", /+ increment mem pointer +/
  "👉", /+ decrement mem pointer +/
  "👆", /+ increment             +/
  "👇", /+ decrement             +/
  "👍", /+ a higher than b       +/
  "👎", /+ a lower than b        +/
  "🫰", /+ a different from b    +/
  "✊", /+ store to register a   +/
  "👊", /+ store to register b   +/
  "🫲", /+ from register a       +/
  "🫱", /+ from register b       +/
  "🫴"  /+ from current mem      +/
  "🤌", /+ comment               +/
  "🖕", /+ break from repeat     +/
  "🤏", /+ next iteration        +/
  "🤞", /+ load random num in a  +/
  "🤙", /+ log value             +/
  "🪬", /+ log all values        +/
*/

auto preprocess(string src)
{
    src = src.replace(" ", "");
    src = src.replace("👋", "#");
    src = src.replace("✋", "!");
    src = src.replace("✍️", "~");
    src = src.replace("✌", "£");
    src = src.replace("🤘", "±");
    src = src.replace("🖖", "%");
    src = src.replace("🫳", "(");
    src = src.replace("👈", "«");
    src = src.replace("👉", "»");
    src = src.replace("👆", "+");
    src = src.replace("👇", "-");
    src = src.replace("👍", ">");
    src = src.replace("👎", "<");
    src = src.replace("🫰", "@");
    src = src.replace("✊", "¶");
    src = src.replace("👊", "$");
    src = src.replace("🫲", "?");
    src = src.replace("🫱", "¦");
    src = src.replace("🫴", ")");
    src = src.replace("🤌", "§");
    src = src.replace("🖕", "¢");
    src = src.replace("🤏", "¤");
    src = src.replace("🤞", "µ");
    src = src.replace("🤙", "&");
    src = src.replace("🪬", "°");

    return src;
}

void main(string[] args)
{
    InitWindow(120, 100, "Test");
    SetTargetFPS(30);

    auto ad = AudioDevice.getInstance;
    while (!ad.isReady){}
    ad.setVolume(1);
    
    noises = 
    [
        new Snd(noisePath.format("clap")),
        new Snd(noisePath.format("click")),
        new Snd(noisePath.format("crack")),
        new Snd(noisePath.format("punch")),
        new Snd(noisePath.format("scratch")),
        new Snd(noisePath.format("slap"))
    ];
    
    ad.close;
}
