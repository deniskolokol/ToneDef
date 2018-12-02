(
SynthDef("output_stereo", {
    arg in=0, out=0, level=1, pos=0,
        gate=1, attack=0.01, sustain=1, release=0.5, ca=3, cr= -3;
    var signal = In.ar(in, 1);
    var env = EnvGen.kr(
        Env.asr(attack, sustain, release, curve:[ca, cr]),
        gate: gate,
        doneAction: 2
    );
    ReplaceOut.ar(out, Pan2.ar(signal * env, pos));
}).send(s);


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


SynthDef("smoozi", {
    arg in=0, out=0, level=0,
        gate=1, attack=0.01, sustain=1, release=0.5, ca=3, cr= -3,
        factor=0.1;
    var signal;
    var input = InFeedback.ar(in, 1);
    var fftbuf = Buffer.alloc(s, 1024);
    var env = EnvGen.kr(
        Env.asr(attack, sustain, release, curve:[ca, cr]),
        gate: gate, doneAction: 2
    );
    var chain = FFT({LocalBuf(1024, 1)}, input);
    chain = PV_MagSmooth(chain, 1-factor);
    signal = IFFT(chain);
    Out.ar(out, signal * env);
}).send(s);


SynthDef("compressor", {
    arg in=0, out=0, level=0,
        gate=1, attack=0.01, sustain=1, release=0.5, ca=3, cr= -3,
        thresh= -60, ratio=2, clampTime=0.01;
    var input = InFeedback.ar(in, 1);
    var env = EnvGen.kr(
        Env.asr(attack, sustain, release, curve:[ca, cr]),
        gate: gate, doneAction: 2
    );
    var signal = Compander.ar(input, input,
        thresh: thresh.dbamp,
        slopeBelow: 1,
        slopeAbove: ratio.reciprocal,
        clampTime: clampTime,
        relaxTime: clampTime*1.5,
        mul: level.dbamp
    );
    Out.ar(out, signal * env);
}).send(s);


SynthDef("pitchfol", {
    arg in=0, out=0, level=0,
        gate=1, attack=0.01, sustain=1, release=0.5, ca=3, cr= -3,
        dry= -60;
    var inFreq, hasFreq, freq, detune, signal;
    var env = EnvGen.kr(
        Env.asr(attack, sustain, release, curve:[ca, cr]),
        gate: gate, doneAction: 2
    );
    var input = InFeedback.ar(in, 1);
    #inFreq, hasFreq = Pitch.kr(input, ampThreshold: 0.02, median: 7);
    freq = Lag.kr(inFreq.cpsmidi.round(1).midicps, 0.05).clip(0, 127).midicps;
    signal = VarSaw.ar(
        freq,
        0,
        LFNoise1.kr(0.3,0.1,0.1),
        Amplitude.kr(in, 0.1, 0.1) * level.dbamp
    );
    signal = Mix([signal * level.dbamp, input * dry.dbamp]);
    Out.ar(out, signal * env);
}).send(s);


SynthDef("distort", {
    arg in=0, out=0, wet=1, level=1,
        gate=1, attack=0.05, sustain=1, release=0.1, ca=3, cr= -3,
        pregain=40;
    // var env = Linen.kr(gate, attack, sustain, release, 2);
    var attenuate = 0.2;
    var env = EnvGen.kr(
        Env.asr(attack, sustain, release, curve:[ca, cr]),
        gate: gate, doneAction: 2
    );
    var input = InFeedback.ar(in, 1);
    var signal = DelayC.ar(
        in: (input * pregain).distort,
        maxdelaytime: 0.01,
        delaytime: 1.0e-3
    );
    var output = ((signal * wet  * attenuate) + (input * (1 - wet))) * level.dbamp;
    XOut.ar(out, env, output);
}).send(s);


SynthDef("echorz", {
    arg in=0, out=0, wet=1, level=1,
        gate=1, attack=0.01, sustain=1, release=0.5, ca=3, cr= -3,
        delaypre=0.04, delaypost=0.05, decaytime=4;
    var signal;
    var input = InFeedback.ar(in, 1);
    var env = EnvGen.kr(
        Env.asr(attack, sustain, release, curve:[ca, cr]),
        gate: gate, doneAction: 2
    );
    var raw, output;
    delaypre = delaypre.clip(0.0001, delaypost*0.99);
    raw = [input, DelayN.ar(input, delaypre, delaypre)];
    4.do({
        raw = AllpassN.ar(raw,
            delaypost,
            [Rand(0.0001, delaypost), Rand(0.0001, delaypost)],
            decaytime,
        )
    });
    signal = Mix.ar(raw) * level.dbamp;
    output = ((signal * wet) + (input * (1 - wet))) * level.dbamp;
    // Out.ar(out, signal * env);
    XOut.ar(out, env, output);
}).send(s);
)