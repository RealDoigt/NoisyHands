import door;
import raylib;
import std.string;
import std.array;
import std.stdio;
import std.conv;
import std.uni;

enum makingNoises = true,
     drawing      = false,
     memSize      = 250,
     noisePath    = "noise/%s.mp3";

enum TokenParts
{
    none,
    end,
    change,
    repeat,
    storeVolume,
    storeSound,
    storeDelay,
    storeMemory,
    storeRegisterA,
    storeRegisterB,
    incrementMemoryPointer,
    decrementMemoryPointer,
    increment,
    decrement,
    higherThan,
    lowerThan,
    differentThan,
    fromRegisterA,
    fromRegisterB,
    fromMemory,
    breakRepeat,
    continueRepeat,
    randomNumber,
    log,
    logEverything
}

enum ErrorTypes
{
    noError,
    missingStorage,  // where is it supposed to store the data?
    missingLocation, // from where does it store the data?
    missingRegister, // which register should be incremented?
    wrongIncrement,  // trying to increment memory directly
    negativePointer, // memory pointer is negative
    nothingBreaks,   // no repeat loop to break from
    nothingContinues,// no repeat loop to continue
}

struct Token
{
    TokenParts tp1, tp2;
    int character, line;
    ErrorTypes error;
}

AudioDevice audio;
Snd[] noises;

ubyte memoryPointer,
      sound, // in drawing mode, this is colour using the tqrrggbb system
      registerA,
      registerB;

auto volume    = 0f,
     debugging = false, // log emojis are ignored when debugging is set to false
     mode      = makingNoises; // true == making noises    false == drawing

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

auto scan(string src)
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

ubyte quarterToValue(ubyte bitValue)
{
    switch (bitValue & 0b0000_0011)
    {
        case 1:  return 64;
        case 2:  return 128;
        case 3:  return 255;
        default: return 0;
    }
}

// transparency quality red red green green blue blue
// transparency 1 and quality 0 -> 50% transparent / 50% opaque
// transparency 1 and quality 1 -> 75% transparent / 25% opaque
// transparency 0 and quality 1 -> 50% darker
auto toColor(ubyte tqrrggbb)
{
    ubyte quality = (tqrrggbb >> 7) | ((tqrrggbb & 0b0100_0000) >> 5);
    ubyte opacity = quality != 3 ? quality == 1 ? 128 : 255 : 64;
    ubyte red     = quarterToValue(tqrrggbb >> 4);
    ubyte green   = quarterToValue(tqrrggbb >> 2);
    ubyte blue    = tqrrggbb.quarterToValue;

    if (quality == 2)
        return Color(red >> 1, green >> 1, blue >> 1, opacity);

    return Color(red, green, blue, opacity);
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
