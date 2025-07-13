s.boot;
b.free;
b = Buffer.read(s, "/Users/deko/Documents/dev_music/effect_plate/test_sounds/eb-blues-riff.wav".standardizePath);
// b = Buffer.read(s, "/Users/deko/Documents/dev_music/Distortion/AQf-1/rock_44100.wav".standardizePath);

~test.free;
~test= {Splay.ar(PlayBuf.ar(b.numChannels, b, loop:1))}.play;
~test = {Splay.ar(SoundIn.ar(0))}.play;
//load synthdefs below
~dist.free;
~dist= Synth(\dist_overdrive, [\bus, 0], addAction: \addToTail);
~dist.set(\preGain, 30, \postGain, 0.1);
~dist.set(\preGain, 10, \postGain, 0.25);
~dist.set(\xFade, 0.5);  //0 to 1
~dist.set(\amount, 0.5)  //some use this

s.scope
~dist.set(\xFade, 1);  //0 to 1
~dist.set(\amount, 0.9)  //some use this
~dist.set(\fc, 4350, \center, 120, \rq, 1.2)




(
//after David Yeh's Thesis - DIGITAL IMPLEMENTATION OF MUSICAL DISTORTION CIRCUITS BY ANALYSIS AND SIMULATION - pdf page 27
SynthDef(\dist_hardclip, {|bus, xFade= 1, preGain= 75, postGain= 0.1|
	var z= In.ar(bus, 2)*preGain;
	z= z.clip2(1);
	XOut.ar(bus, xFade, z*postGain);
}, #[\ir, 0.05, 0.05, 0.05]).add;
SynthDef(\dist_tanh, {|bus, xFade= 1, preGain= 75, postGain= 0.1|
	var z= In.ar(bus, 2)*preGain;
	z= z.tanh;
	XOut.ar(bus, xFade, z*postGain);
}, #[\ir, 0.05, 0.05, 0.05]).add;
SynthDef(\dist_atan, {|bus, xFade= 1, preGain= 75, postGain= 0.1|
	var z= In.ar(bus, 2)*preGain;
	z= z.atan/0.5pi;
	XOut.ar(bus, xFade, z*postGain);
}, #[\ir, 0.05, 0.05, 0.05]).add;
SynthDef(\dist_softcubic, {|bus, xFade= 1, preGain= 75, postGain= 0.1|
	var z= In.ar(bus, 2)*preGain;
	z= [z< -1 * -2/3, ((z>= -1)&(z<=1))*(z-(z.pow(3)/3)), z>1*2/3].sum;
	XOut.ar(bus, xFade, z*postGain);
}, #[\ir, 0.05, 0.05, 0.05]).add;
SynthDef(\dist_approxtanh, {|bus, xFade= 1, preGain= 75, postGain= 0.1, n= 2.5|
	var z= In.ar(bus, 2)*preGain;
	z= z/(1+z.abs.pow(n)).pow(1/n);
	XOut.ar(bus, xFade, z*postGain);
}, #[\ir, 0.05, 0.05, 0.05, 0.05]).add;

//sc built-in
SynthDef(\dist_softclip, {|bus, xFade= 1, preGain= 75, postGain= 0.1|
	var z= In.ar(bus, 2)*preGain;
	z= z.softclip;
	XOut.ar(bus, xFade, z*postGain);
}, #[\ir, 0.05, 0.05, 0.05]).add;
SynthDef(\dist_distort, {|bus, xFade= 1, preGain= 75, postGain= 0.1|
	var z= In.ar(bus, 2)*preGain;
	z= z.distort;
	XOut.ar(bus, xFade, z*postGain);
}, #[\ir, 0.05, 0.05, 0.05]).add;

//after Partice Tarrabia and Bram de Jong
SynthDef(\dist_shaper, {|bus, xFade= 1, preGain= 75, postGain= 0.1, amount= 0.5|
	var z= In.ar(bus, 2)*preGain;
	var k= 2*amount/(1-amount);
	z= (1+k)*z/(1+(k*z.abs));
	XOut.ar(bus, xFade, z*postGain);
}, #[\ir, 0.05, 0.05, 0.05, 0.05]).add;

//after LandonPD https://forum.pdpatchrepo.info/topic/9088/expressive-distortion-by-transfer-function
//amount 0.001 to 1
SynthDef(\dist_landon_transfer_pd, {|bus, xFade= 1, preGain= 75, postGain= 0.1, amount= 0.5, numSamp= 3000|
	var z= In.ar(bus, 2)*preGain;
	var rms= (RunningSum.ar(z.squared, numSamp)/numSamp).sqrt;
	z= z/((amount-1.001).abs+z.abs);
	z= z*rms;
	XOut.ar(bus, xFade, z*postGain);
}, #[\ir, 0.05, 0.05, 0.05, 0.05, \ir]).add;
//after LandonPD https://forum.pdpatchrepo.info/topic/9077/expressive-distortion-for-your-guitar-or-any-input
//amount 0 to 1
SynthDef(\dist_landon_input_pd, {|bus, xFade= 1, preGain= 75, postGain= 0.1, amount= 0.5, numSamp= 3000|
	var z= In.ar(bus, 2)*preGain;
	var rms= (RunningSum.ar(z.squared, numSamp)/numSamp).sqrt;
	z= (z*amount*20000).clip2(1);
	z= (z*rms).clip2(0.707);
	XOut.ar(bus, xFade, z*postGain);
}, #[\ir, 0.05, 0.05, 0.05, 0.05, \ir]).add;

//after fx.fuzz https://github.com/megrimm/pd-fresh
//preGain ?
//clip ?
//fuzz ?
//postgain ?
//lopass ?
//difference 0/1

SynthDef(\dist_megrimm_fuzz, {|bus, xFade= 1, preGain= 75, postGain= 0.1, clip= 0.3, fuzz= 0.5, difference= 0, lopass= 0.895|
	var lop= {|sig, freq| OnePole.ar(sig, exp(-2pi*freq*SampleDur.ir))};
	var z= In.ar(bus, 2)*preGain*0.05;
	var x, y;
	clip= clip*0.99+0.01;
	x= z.clip2(clip);
	y= x-((z-x)*(fuzz*10)).clip2(clip);
	z= z*4;
	y= y*4;
	z= ((z-y)*(difference>0))+(y*(difference<1));
	z= lop.(z, lopass.squared*20000);
	XOut.ar(bus, xFade, z*postGain);
}, #[\ir, 0.05, 0.05, 0.05, 0.05, 0.05, 0.05, 0.05]).add;

SynthDef(\Dsaturation_pd, {|bus, xFade= 1, preGain= 75, postGain= 0.1|
	var insanity= -1.8;  //vary this and rebuild synthdef
	var lop= {|sig, freq| OnePole.ar(sig, exp(-2pi*freq*SampleDur.ir))};
	var hip= {|sig, freq| sig-lop.(sig, freq)};
	var tran= LocalBuf(256, 1).set({|i| (i*0.3).tan.pow(insanity).cos.min(1)}!256);
	var z= In.ar(bus, 2)*preGain/400;
	z= z*128+129;
	z= IndexL.ar(tran, z);
	z= hip.(lop.(z, 20000), 5)*2;
	XOut.ar(bus, xFade, z*postGain);
}, #[\ir, 0.05, 0.05, 0.05]).add;


SynthDef(\dist_overdrive, {|bus, xFade= 1, preGain= 75, postGain= 0.1|
    var z= In.ar(bus, 2)*preGain;
    z= (z.tanh * (preGain*0.5+0.1)).atan.clip2;
    XOut.ar(bus, xFade, z*postGain);
}, #[\ir, 0.05, 0.05, 0.05]).add;


SynthDef(\Dcabinet, {|bus, xFade= 1, preGain= 75, postGain= 0.1|
    var input = In.ar(bus, 2)*preGain*0.05;
    var signal = input + (HPF.ar(input, 3000) * -50.dbamp);
    signal = (signal * 32.dbamp).tanh;
    signal = RLPF.ar(signal, 3000, 0.5);
    signal = (signal * 32.dbamp).tanh;
    signal = RLPF.ar(signal, 500, 0.5);
    signal = (signal * 32.dbamp).tanh;
    signal = BHiShelf.ar(signal, 3200, 1, -3.0);
    signal = LeakDC.ar(signal);
    signal = DelayC.ar(signal, 0.1, SinOsc.kr(2, [0, 1pi]).range(0, 1e-4));
	XOut.ar(bus, xFade, signal * postGain);
}, #[\ir, 0.05, 0.05, 0.05]).add;

)

// a = (-1,-0.9..1).sinPi
// b = a.collect { arg z; (z*75).atan/0.5pi };
// c = a.collect { arg z; ((z*75).tanh * (75*0.5+0.1)).atan.clip2 };
// [a, b, c].plot
//
// z= (z.tanh * (preGain*0.5+0.1)).atan;