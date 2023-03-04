import raylib_misc;
import std.string;

enum noisePath = "noise/%s.mp3";

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
    
    
}
