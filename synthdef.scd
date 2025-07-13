(
Server.default = s = Server.local;
s.boot();
s.waitForBoot({
    SynthDef("sound_in", {
        arg in=0, out=0, level=1,
            gate=1, attack=0.01, sustain=1, release=0.5, ca=3, cr= -3;
        var signal = SoundIn.ar(in);
        var env = EnvGen.kr(
            Env.asr(attack, sustain, release, curve:[ca, cr]),
            gate: gate,
            doneAction: 2
        );
        Out.ar(out, (signal * env))
    }).send(s);

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
        arg bufnum, out=0, level=1, loop=1,
            gate=1, attack=0.01, sustain=1, release=0.5, ca=3, cr= -3;
        var signal = PlayBuf.ar(1,
            bufnum,
            BufRateScale.kr(bufnum),
            loop: loop
        );
        var env = EnvGen.kr(
            Env.asr(attack, sustain, release, curve:[ca, cr]),
            gate: gate,
            doneAction: 2
        ) * level.dbamp;
        Out.ar(out, signal * env);
    }).send(s);


    SynthDef("smoozi", {
        arg in=0, out=0, level=0, wet=1,
            gate=1, attack=0.01, sustain=1, release=0.5, ca=3, cr= -3,
            factor=0.1;
        var signal, output;
        var input = InFeedback.ar(in, 1);
        var fftbuf = Buffer.alloc(s, 1024);
        var env = EnvGen.kr(
            Env.asr(attack, sustain, release, curve:[ca, cr]),
            gate: gate, doneAction: 2
        );
        var chain = FFT({LocalBuf(1024, 1)}, input);
        chain = PV_MagSmooth(chain, 1-factor);
        signal = IFFT(chain);
        output = ((signal * wet * level.dbamp) + (input * (1 - wet)));
        Out.ar(out, output * env);
    }).send(s);


    SynthDef("compressor", {
        arg in=0, out=0, level=0, wet=1,
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
        var output = ((signal * wet * level.dbamp) + (input * (1 - wet)));
        Out.ar(out, output * env);
    }).send(s);


    SynthDef("compressor_mb", {
        arg in=0, out=0, level=6.2, wet=1,
            gate=1, attack=0.01, sustain=1, release=0.5, ca=3, cr= -3,
            freqLowPass=245, rqLowPass=0.9,
            freqBandPass=5463, bandwidthOctaves=4.47,
            freqHighPass=11172, rqHighPass=0.9,
            threshLow= -18, ratioLow=2, clampTimeLow=0.0201, relaxTimeLow=0.109, gainLow=1.05,
            threshMid= -18, ratioMid=2, clampTimeMid=0.0206, relaxTimeMid=0.109, gainMid=0,
            threshHigh= -18, ratioHigh=2, clampTimeHigh=0.0206, relaxTimeHigh=0.109, gainHigh=0.9495;
        var input = InFeedback.ar(in, 1);
        var env = EnvGen.kr(
            Env.asr(attack, sustain, release, curve:[ca, cr]),
            gate: gate, doneAction: 2
        );
        var inpLow, inpMid, inpHigh;
        var bandLow, bandMid, bandHigh;
        var signal, output;

        // inputs
        inpLow = BLowPass.ar(input, freq: freqLowPass, rq: rqLowPass);
        inpMid = BBandPass.ar(input, freq: freqBandPass, bw: bandwidthOctaves);
        inpHigh = BHiPass.ar(input, freq: freqHighPass, rq:rqHighPass);

        // comp bands
        bandLow = Compander.ar(inpLow, inpLow,
            thresh: threshLow.dbamp,
            slopeBelow: 1,
            slopeAbove: ratioLow.reciprocal,
            clampTime: clampTimeLow,
            relaxTime: relaxTimeLow,
            mul: gainLow.dbamp
        );
        bandMid = Compander.ar(inpMid, inpMid,
            thresh: threshMid.dbamp,
            slopeBelow: 1,
            slopeAbove: ratioMid.reciprocal,
            clampTime: clampTimeMid,
            relaxTime: relaxTimeMid,
            mul: gainMid.dbamp
        );
        bandHigh = Compander.ar(inpHigh, inpHigh,
            thresh: threshHigh.dbamp,
            slopeBelow: 1,
            slopeAbove: ratioHigh.reciprocal,
            clampTime: clampTimeHigh,
            relaxTime: relaxTimeHigh,
            mul: gainHigh.dbamp
        );

        // mix up
        signal = bandLow + bandMid + bandHigh;
        // apply master gain (warning: in compressor master gain
        // is applied to the wet signal, not the final mix)
        output = ((signal * wet * level.dbamp) + (input * (1 - wet)));
        Out.ar(out, output * env);
    }).send(s);


    SynthDef("pitchfol", {
        arg in=0, out=0, level=0, wet=1,
            gate=1, attack=0.01, sustain=1, release=0.5, ca=3, cr= -3,
            dry= -60;
        var inFreq, hasFreq, freq, detune, signal, output;
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
        output = ((signal * wet * level.dbamp) + (input * (1 - wet)));
        Out.ar(out, output * env);
    }).send(s);


    SynthDef("distort", {
        arg in=0, out=0, level=1, wet=1,
            gate=1, attack=0.05, sustain=1, release=0.1, ca=3, cr= -3,
            pregain=40, cutoff=8000, insanity= -1.8;
        var input, signal, output;
        var lop, hip, tran;
        var attenuate = -20.dbamp;
        var env = EnvGen.kr(
            Env.asr(attack, sustain, release, curve:[ca, cr]),
            gate: gate, doneAction: 2
        );
        input = InFeedback.ar(in, 1);

        // // variant 1
        // signal = DelayC.ar(
        //     in: (input * pregain).distort,
        //     maxdelaytime: 0.01,
        //     delaytime: 1.0e-3
        // );

        // // variant 2
        // signal = input + (HPF.ar(input, 3000) * -50.dbamp);
        // signal = (signal * 32.dbamp).tanh;
        // signal = RLPF.ar(signal, 3000, 0.5);
        // signal = (signal * 32.dbamp).tanh;
        // signal = RLPF.ar(signal, 500, 0.5);
        // signal = (signal * 32.dbamp).tanh;
        // signal = BHiShelf.ar(signal, 3200, 1, -3.0);
        // signal = LeakDC.ar(signal);
        // signal = DelayC.ar(signal, 0.1, SinOsc.kr(2, [0, 1pi]).range(0, 1e-4));

        // // variant 3
        // signal = (input * pregain).tanh;
        // signal = (signal * (pregain*0.5+0.1)).atan;
        // signal = BPeakEQ.ar(signal, XLine.kr(cutoff*0.25, 100, 0.3), 2.0, 8);
        // signal = signal + DelayC.ar(signal, 0.01, SinOsc.ar(cutoff/2000).range(0.0, 0.001));
        // signal = RLPF.ar(signal, cutoff, 0.7);
        // signal = (signal * 0.6).clip(-1, 1);

        // variant 4
        lop = {|sig, freq| OnePole.ar(sig, exp(-2pi*freq*SampleDur.ir))};
        hip = {|sig, freq| sig-lop.(sig, freq)};
        tran = LocalBuf(256, 1).set({|i| (i*0.3).tan.pow(insanity).cos.min(1)}!256);
        signal = (input ! 2) * pregain / 400;
        signal = signal * 128 + 129;
        signal = IndexL.ar(tran, signal);
        signal = hip.(lop.(signal, cutoff), 5)*2;

        output = ((signal * wet * attenuate) + (input * (1 - wet))) * level.dbamp;
        Out.ar(out, output * env);
    }).send(s);


    SynthDef("fuzz", {
        arg in=0, out=0, level=1, wet=1,
            gate=1, attack=0.05, sustain=1, release=0.1, ca=3, cr= -3,
            pregain=40, amount=0.5;
        var input, signal, output;
        var lop, hip, tran;
        var attenuate = -20.dbamp;
        var env = EnvGen.kr(
            Env.asr(attack, sustain, release, curve:[ca, cr]),
            gate: gate, doneAction: 2
        );
        input = InFeedback.ar(in, 1);

        signal = (input ! 2) * pregain;
        signal = (signal.tanh * (pregain * amount + 0.1)).atan.clip2;

        output = ((signal * wet * attenuate) + (input * (1 - wet))) * level.dbamp;
        Out.ar(out, output * env);
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
        Out.ar(out, output * env);
        // XOut.ar(out, env, output);
    }).send(s);
    });
)