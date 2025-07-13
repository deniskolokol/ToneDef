(
var cmdPeriodFunc;

// Window
var win = Window.new("Server Levels", Rect(0, Window.screenBounds.height, 350, 250));
var meterView = ServerMeterView.new(s, win, 0@0, s.options.numInputBusChannels, s.options.numOutputBusChannels);

// Test samples
var currentDir = PathName(thisProcess.nowExecutingPath).pathOnly;
var sampleDir = currentDir +/+ "test_sounds";
var confFile = currentDir +/+ "plate.conf";
var samples=List.new, sampleLabels=List.new, samplesDD;

// Rack
var rack = RedEffectsRack([RedEfxTank, RedEfxGuit, RedEfxDist, RedEfxComb]);
var gui = RedEffectsRackGUI(rack, Point(0, 250));


"-> Reading test samples...".postln;
PathName.new(sampleDir).entries.do { |f, i|
    if (f.fullPath.endsWith(".wav") ||
        (f.fullPath.endsWith(".aif")) ||
        (f.fullPath.endsWith(".aiff"))
    ) {
        samples.add(Buffer.readChannel(s, f.fullPath, channels: [0]));
        sampleLabels.add(f.fileName);
    }
};

win.front; // show the window

SynthDef("looper_mono", {
    arg bufnum, out=0, level=1,
        gate=1, attack=0.01, sustain=1, release=0.5, ca=3, cr= -3;
    var signal = PlayBuf.ar(1,
        bufnum,
        BufRateScale.kr(bufnum),
        loop: 1
    );
    var env = EnvGen.kr(
        Env.asr(attack, sustain, release, curve:[ca, cr]),
        gate: gate,
        doneAction: 2
    ) * level.dbamp;
    Out.ar(out, signal * env);
}).send(s);

cmdPeriodFunc = {
    meterView.stop;
    win.close;
};
CmdPeriod.add(cmdPeriodFunc);
win.onClose = {
    CmdPeriod.remove(cmdPeriodFunc);
};
)


n.set(\gate, 0);
b.free;

a = {SoundIn.ar(0, 1)}.play;

r = RedEffectsRack([RedEfxGuit, RedEfxDist, RedEfxDist, RedEfxZzzz, RedEfxComb]);
c = RedEffectsRackGUI(r, Point(0, 250));
s.plotTree;
r.cvs;
c.redEffectsRack.efxs;
r.verbMxix= 0.75;
r.verbDamp= 0.7;

a.free;
r.free;
b.stop;
c.close;