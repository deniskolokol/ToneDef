// Audio through
~y.free;
~y = {
	var in=0;
    var sig = SoundIn.ar(in, 1);
	Out.ar(5, sig);
}.play


// fuzz 1
~x.free;
~x = {
	var in=0, sig, envTime, knee, out, amp=0.2;

    sig = SoundIn.ar(in, 1);
    // sig = PlayBuf.ar(1, ~buf, BufRateScale.kr(~buf), loop: 1);
    // sig = sig!2;

    envTime = MouseX.kr(1.0e-3, 0.1e-3);
    knee = MouseY.kr(0, -90).dbamp;
    out = DelayC.ar(sig, 0.01, envTime * 0.5) * EnvFollow.ar(sig, 1 - (envTime * SampleRate.ir).reciprocal).max(knee).reciprocal;
    out = out ! 2 * amp;

	Out.ar(0, out);
}.play

// fuzz 2
(
SynthDef(\fuzz0, { arg in=0, out=0, pregain=40, amp=0.2, gate=1;
    var sig, env;
    // sig = PlayBuf.ar(1, ~buf, BufRateScale.kr(~buf), loop: 1);
    sig = SoundIn.ar(in, 1);
    env = Linen.kr(gate, 0.05, 1, 0.1, 2);
    XOut.ar(out, env, (sig!2 * pregain).distort * amp);
}, [\ir, 0.1, 0.1, 0]).send;
)
a = Synth(\fuzz0, addAction:\addToTail)


// 3
(
SynthDef(\flanger, { arg out=0, in=0, delay=0.1, depth=0.08, rate=0.06, fdbk=0.0, decay=0.0;
    var input, maxdelay, maxrate, dsig, mixed, local;
    maxdelay = 0.013;
    maxrate = 10.0;
    // input = SoundIn.ar(in, 1);
    input = PlayBuf.ar(1, ~buf, BufRateScale.kr(~buf), loop: 1);
    local = LocalIn.ar(1);
    dsig = AllpassL.ar( // the delay (you could use AllpassC (put 0 in decay))
        input + (local * fdbk),
        maxdelay * 2,
        LFPar.kr( // very similar to SinOsc (try to replace it) - Even use LFTri
            rate * maxrate,
            0,
            depth * maxdelay,
            delay * maxdelay),
        decay);
    mixed = input + dsig;
    LocalOut.ar(mixed);
    Out.ar([out, out+1], mixed);
}).send(s);
)

a = Synth(\flanger, [\in, 0], addAction:\addToTail)