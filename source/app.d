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
    play,
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
    greaterThan,
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
    nothingEnds,     // no if/loop/comment to end
    invalidToken
}

struct Token
{
    TokenParts tp1, tp2;
    int column, line;
    ErrorTypes error;

    this(TokenParts tp1, TokenParts tp2, int column, int line, ErrorTypes error = ErrorTypes.noError)
    {
        this.tp1    = tp1;
        this.tp2    = tp2;
        this.column = column;
        this.line   = line;
        this.error  = error;
    }

    this(TokenParts tp1, int column, int line, ErrorTypes error = ErrorTypes.noError)
    {
        this.tp1    = tp1;
        this.tp2    = TokenParts.none;
        this.column = column;
        this.line   = line;
        this.error  = error;
    }

    this(int column, int line)
    {
        this.tp1    = TokenParts.none;
        this.tp2    = TokenParts.none;
        this.column = column;
        this.line   = line;
        this.error  = ErrorTypes.invalidToken;
    }
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
  "👈", /+ decrement mem pointer +/
  "👉", /+ increment mem pointer +/
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

// probably the closest thing to a scanner in the old traditional sense
auto scan(string src)
{
    src = src.replace("👋", "#");
    src = src.replace("✋", "!");
    src = src.replace("✍️", "~");
    src = src.replace("👌", "*");
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

// TODO:
template GenCase(string op)
{
    const char[] GenCase = "";
}

auto lex(string scannedSrc)
{

    int index, line = 1, column = 1;
    Token[] tokens;

    while (index < scannedSrc.length)
    {
        switch (scannedSrc[index])
        {
            // monopart tokens
            case '#': tokens ~= Token(TokenParts.play, column, line); break;
            case '!': tokens ~= Token(TokenParts.end, column, line); break;
            case '~': tokens ~= Token(TokenParts.change, column, line); break;
            case '*': tokens ~= Token(TokenParts.repeat, column, line); break;
            case '«': tokens ~= Token(TokenParts.decrementMemoryPointer, column, line); break;
            case '»': tokens ~= Token(TokenParts.incrementMemoryPointer, column, line); break;
            case '>': tokens ~= Token(TokenParts.greaterThan, column, line); break;
            case '<': tokens ~= Token(TokenParts.lowerThan, column, line); break;
            case '@': tokens ~= Token(TokenParts.differentThan, column, line); break;
            case '¢': tokens ~= Token(TokenParts.breakRepeat, column, line); break;
            case '¤': tokens ~= Token(TokenParts.continueRepeat, column, line); break;
            case 'µ': tokens ~= Token(TokenParts.randomNumber, column, line); break;
            case '°': tokens ~= Token(TokenParts.logEverything, column, line); break;

            case '?':
                if (index + 1 < scannedSrc.length)
                {
                    switch (scannedSrc[index + 1])
                    {
                        case '£': tokens ~= Token(TokenParts.fromRegisterA, TokenParts.storeVolume, column, line); break;
                        case '±': tokens ~= Token(TokenParts.fromRegisterA, TokenParts.storeSound, column, line); break;
                        case '%': tokens ~= Token(TokenParts.fromRegisterA, TokenParts.storeDelay, column, line); break;
                        case '(': tokens ~= Token(TokenParts.fromRegisterA, TokenParts.storeMemory, column, line); break;
                        case '¶': tokens ~= Token(TokenParts.fromRegisterA, TokenParts.storeRegisterA, column, line, ErrorTypes.invalidToken); break;
                        case '$': tokens ~= Token(TokenParts.fromRegisterA, TokenParts.storeRegisterB, column, line); break;
                        default: tokens ~= Token(TokenParts.fromRegisterA, column, line, ErrorTypes.invalidToken);
                    }
                    ++index;
                }

                else tokens ~= Token(TokenParts.fromRegisterA, column, line, ErrorTypes.missingStorage);
                break;

            case '¦':
                if (index + 1 < scannedSrc.length)
                {
                    switch (scannedSrc[index + 1])
                    {
                        case '£': tokens ~= Token(TokenParts.fromRegisterB, TokenParts.storeVolume, column, line, ErrorTypes.missingRegister); break;
                        case '±': tokens ~= Token(TokenParts.fromRegisterB, TokenParts.storeSound, column, line, ErrorTypes.missingRegister); break;
                        case '%': tokens ~= Token(TokenParts.fromRegisterB, TokenParts.storeDelay, column, line, ErrorTypes.missingRegister); break;
                        case '(': tokens ~= Token(TokenParts.fromRegisterB, TokenParts.storeMemory, column, line, ErrorTypes.missingRegister); break;
                        case '¶': tokens ~= Token(TokenParts.fromRegisterB, TokenParts.storeRegisterA, column, line); break;
                        case '$': tokens ~= Token(TokenParts.fromRegisterB, TokenParts.storeRegisterB, column, line, ErrorTypes.invalidToken); break;
                        default: tokens ~= Token(TokenParts.fromRegisterB, column, line, ErrorTypes.invalidToken);
                    }
                    ++index;
                }

                else tokens ~= Token(TokenParts.fromRegisterB, column, line, ErrorTypes.missingStorage);
            break;

            case ')':
                if (index + 1 < scannedSrc.length)
                {
                    switch (scannedSrc[index + 1])
                    {
                        case '£': tokens ~= Token(TokenParts.fromMemory, TokenParts.storeVolume, column, line); break;
                        case '±': tokens ~= Token(TokenParts.fromMemory, TokenParts.storeSound, column, line); break;
                        case '%': tokens ~= Token(TokenParts.fromMemory, TokenParts.storeDelay, column, line); break;
                        case '(': tokens ~= Token(TokenParts.fromMemory, TokenParts.storeMemory, column, line, ErrorTypes.invalidToken); break;
                        case '¶': tokens ~= Token(TokenParts.fromMemory, TokenParts.storeRegisterA, column, line); break;
                        case '$': tokens ~= Token(TokenParts.fromMemory, TokenParts.storeRegisterB, column, line); break;
                        default: tokens ~= Token(TokenParts.fromMemory, column, line, ErrorTypes.invalidToken);
                    }
                    ++index;
                }

                else tokens ~= Token(TokenParts.fromMemory, column, line, ErrorTypes.missingStorage);
            break;

            case '§':
                while (index + 1 < scannedSrc.length || scannedSrc[index + 1] != '!')
                    ++index; // consumming the commented out characters
                break;

            // tokens used incorrectly
            case '£': tokens ~= Token(TokenParts.storeVolume, column, line, ErrorTypes.missingLocation); break;
            case '±': tokens ~= Token(TokenParts.storeSound, column, line, ErrorTypes.missingLocation); break;
            case '%': tokens ~= Token(TokenParts.storeDelay, column, line, ErrorTypes.missingLocation); break;
            case '(': tokens ~= Token(TokenParts.storeMemory, column, line, ErrorTypes.missingLocation); break;
            case '¶': tokens ~= Token(TokenParts.storeRegisterA, column, line, ErrorTypes.missingLocation); break;
            case '$': tokens ~= Token(TokenParts.storeRegisterB, column, line, ErrorTypes.missingLocation); break;
            case '&': tokens ~= Token(TokenParts.log, column, line, ErrorTypes.missingLocation); break;
            case '+': tokens ~= Token(TokenParts.increment, column, line, ErrorTypes.missingRegister); break;
            case '-': tokens ~= Token(TokenParts.decrement, column, line, ErrorTypes.missingRegister); break;
            default: tokens ~= Token(column, line);
        }

        ++index;
    }

    return tokens;
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
        new Snd(noisePath.format("slap")),
        new Snd(noisePath.format("tap")),
        new Snd(noisePath.format("taps"))
    ];
    
    ad.close;
}
