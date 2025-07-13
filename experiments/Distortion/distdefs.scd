
(
Spec.add(\bus, \audiobus.asSpec);
Spec.add(\xFade, ControlSpec(0, 1, 'lin', 0, 1));
Spec.add(\preGain, ControlSpec(0, 200, 'lin', 0, 75));
Spec.add(\postGain, ControlSpec(0, 2, 'lin', 0, 0.1));

SynthDescLib(\distortion);  //maybe put in separate lib?

//--after David Yeh's Thesis - DIGITAL IMPLEMENTATION OF MUSICAL DISTORTION CIRCUITS BY ANALYSIS AND SIMULATION - pdf page 27
SynthDef(\DhardClip, {|bus, xFade= 1, preGain= 75, postGain= 0.1|
	var z= In.ar(bus, 2)*preGain;
	z= z.clip2(1);
	XOut.ar(bus, xFade, z*postGain);
}).add(\distortion);
SynthDef(\Dtanh, {|bus, xFade= 1, preGain= 75, postGain= 0.1|
	var z= In.ar(bus, 2)*preGain;
	z= z.tanh;
	XOut.ar(bus, xFade, z*postGain);
}).add(\distortion);
SynthDef(\Datan, {|bus, xFade= 1, preGain= 75, postGain= 0.1|
	var z= In.ar(bus, 2)*preGain;
	z= z.atan/0.5pi;
	XOut.ar(bus, xFade, z*postGain);
}).add(\distortion);
SynthDef(\Dsoftcubic, {|bus, xFade= 1, preGain= 75, postGain= 0.1|
	var z= In.ar(bus, 2)*preGain;
	z= [z< -1 * -2/3, ((z>= -1)&(z<=1))*(z-(z.pow(3)/3)), z>1*2/3].sum;
	XOut.ar(bus, xFade, z*postGain);
}).add(\distortion);
SynthDef(\DapproxTanh, {|bus, xFade= 1, preGain= 75, postGain= 0.1, n= 2.5|
	var z= In.ar(bus, 2)*preGain;
	z= z/(1+z.abs.pow(n)).pow(1/n);
	XOut.ar(bus, xFade, z*postGain);
}).metadata_((
	specs: (
		n: ControlSpec(1, 10, 'lin', 0, 2.5)
	)
)).add(\distortion);

//--using built-in methods
SynthDef(\DsoftClip, {|bus, xFade= 1, preGain= 75, postGain= 0.1|
	var z= In.ar(bus, 2)*preGain;
	z= z.softclip;
	XOut.ar(bus, xFade, z*postGain);
}).add(\distortion);
SynthDef(\Ddistort, {|bus, xFade= 1, preGain= 75, postGain= 0.1|
	var z= In.ar(bus, 2)*preGain;
	z= z.distort;
	XOut.ar(bus, xFade, z*postGain);
}).add(\distortion);

//--after Partice Tarrabia and Bram de Jong
SynthDef(\Dshaper, {|bus, xFade= 1, preGain= 75, postGain= 0.1, amount= 0.5|
	var z= In.ar(bus, 2)*preGain;
	var k= 2*amount/(1-amount);
	z= (1+k)*z/(1+(k*z.abs));
	XOut.ar(bus, xFade, z*postGain);
}).metadata_((
	specs: (
		amount: ControlSpec(0.0001, 0.9999, 'lin', 0, 0.5)
	)
)).add(\distortion);

//--after LandonPD https://forum.pdpatchrepo.info/topic/9077/expressive-distortion-for-your-guitar-or-any-input
SynthDef(\DlandonDist_pd, {|bus, xFade= 1, preGain= 75, postGain= 0.1, amount= 0.5|
	var z= In.ar(bus, 2)*preGain;
	var num= \numSamp.ir(3000);
	var rms= (RunningSum.ar(z.squared, num)/num).sqrt;
	z= (z*amount*20000).clip2(1);
	z= (z*rms).clip2(0.707);
	XOut.ar(bus, xFade, z*postGain);
}).metadata_((
	specs: (
		amount: ControlSpec(0.001, 1, 'lin', 0, 0.5),
		numSamp: ControlSpec(1, 10000, 'lin', 1, 3000)
	)
)).add(\distortion);
//--after LandonPD https://forum.pdpatchrepo.info/topic/9088/expressive-distortion-by-transfer-function
SynthDef(\DlandonTransfer_pd, {|bus, xFade= 1, preGain= 75, postGain= 0.1, amount= 0.5|
	var z= In.ar(bus, 2)*preGain*0.25;
	var num= \numSamp.ir(3000);
	var rms= (RunningSum.ar(z.squared, num)/num).sqrt;
	z= z/((amount-1.001).abs+z.abs);
	z= z*rms;
	XOut.ar(bus, xFade, z*postGain);
}).metadata_((
	specs: (
		amount: ControlSpec(0.001, 1, 'lin', 0, 0.5),
		numSamp: ControlSpec(1, 10000, 'lin', 1, 3000)
	)
)).add(\distortion);

//--after fx.fuzz https://github.com/megrimm/pd-fresh
SynthDef(\DgrimmFuzz_pd, {|bus, xFade= 1, preGain= 75, postGain= 0.1, clip= 0.3, fuzz= 0.5, difference= 0, lopass= 0.895|
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
}).metadata_((
	specs: (
		clip: ControlSpec(0, 1, 'lin', 0, 0.3),
		fuzz: ControlSpec(0, 1, 'lin', 0, 0.5),
		difference: ControlSpec(0, 1, 'lin', 1, 0),
		lopass: ControlSpec(0, 1, 'lin', 0, 0.895)
	)
)).add(\distortion);

//--after formuls https://forum.pdpatchrepo.info/topic/10589/saturation-abstraction
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
}).add(\distortion);

//--after RedEfxDist
SynthDef(\DredEfxDist, {|bus, xFade= 1, preGain= 75, postGain= 0.1, amount= 0.75|
	var z= In.ar(bus, 2)*preGain*0.015;
	z= SinOsc.ar(0, z*(1+(amount*8pi)));
	XOut.ar(bus, xFade, z*postGain);
}).metadata_((
	specs: (
		amount: ControlSpec(0, 10, 'lin', 0, 0.75)
	)
)).add(\distortion);

//--after Saturation by Batuhan Bozkurt, sc-users 090701
SynthDef(\Dsaturation, {|bus, xFade= 1, preGain= 75, postGain= 0.1, amount= 0.75, fc= 3500, center= 120, rq= 0.707|
	var z= In.ar(bus, 2)*preGain*0.2;
	var k= 2*amount/(1-amount);
	var wet= ((1+k)*z)/(1+(k*z.abs));
	wet= MidEQ.ar((LPF.ar(wet, fc*#[1, 1.1])*0.5), center, rq, 8);
	XOut.ar(bus, xFade, wet*postGain);
}).variants_((
	low: [xFade:1, preGain:75, postGain:0.1, amount:0.9, fc:1500, center:80, rq:10],
	hi: [xFade:1, preGain:75, postGain:0.1, amount: 0.5, fc:8000, center:1800, rq:1.5]
)).metadata_((
	specs: (
		amount: ControlSpec(0, 0.9999, 'lin', 0, 0.75),
		fc: ControlSpec(20, 20000, 'exp', 0, 3500),
		center: ControlSpec(20, 20000, 'exp', 0, 120),
		rq: ControlSpec(0.001, 25, 'exp', 0, 0.707)
	)
)).add(\distortion);

//--after AudioMSG from sc3-plugins JoshUGens
SynthDef(\DaudioMSG, {|bus, xFade= 1, preGain= 75, postGain= 0.1, index= 0.5pi|
	var z= In.ar(bus, 2)*preGain*0.1;
	z= SinOsc.ar(0, (z*0.5pi)+SinOsc.ar(0, z*2pi, index));
	XOut.ar(bus, xFade, z*postGain);
}).metadata_((
	specs: (
		index: ControlSpec(0, 3pi, 'lin', 0, 0.5pi)
	)
)).add(\distortion);

//--after Denis' experimentation
SynthDef(\Doverdrive, {|bus, xFade= 1, preGain= 75, postGain= 0.1, amount=0.5|
	var z= In.ar(bus, 2)*preGain;
    z= (z.tanh * (preGain*amount+(amount/5))).atan.clip2;
	XOut.ar(bus, xFade, z*postGain);
}).variants_((
    soft: [xFade:1, preGain:10, postGain:0.175, amount:0.835],
    warm: [xFade:1, preGain:13.5, postGain:0.25, amount:0.5],
	kick: [xFade:1, preGain:25, postGain:0.2, amount:0.75]
)).metadata_((
	specs: (
		amount: ControlSpec(0.1, 1, 'lin', 0, 0.75)
	)
)).add(\distortion);

//--after Denis
SynthDef(\Difuzz, {|bus, xFade= 1, preGain= 75, postGain= 0.1, lowPass=500, hiShelf=3200|
    var z= In.ar(bus, 2);
	z= z + (HPF.ar(z, 3000) * -50.dbamp);
    z= RLPF.ar((z * preGain).tanh, 3000, 0.5);
    z= RLPF.ar((z * preGain).tanh, lowPass, 0.5);
    z= BHiShelf.ar((z * preGain).tanh, hiShelf, 1, -3.0);
    z= DelayC.ar(LeakDC.ar(z), 1e-4, SinOsc.kr(2, #[0, 1pi]).range(0, 1e-4));
	XOut.ar(bus, xFade, z*postGain);
}).variants_((
	stoner: [xFade:0.5, preGain:17, postGain:0.1pi, lowPass:285, hiShelf:3200],
	banshee: [xFade:1, preGain:40, postGain:0.1, lowPass:500, hiShelf:12660],
    attack: [xFade:1, preGain:40, postGain:0.1, lowPass:830, hiShelf:2200]
)).metadata_((
	specs: (
        lowPass: ControlSpec(175, 1000, 'lin', 0, 500),
		hiShelf: ControlSpec(1000, 20000, 'lin', 0, 3200),
	)
)).add(\distortion);
)