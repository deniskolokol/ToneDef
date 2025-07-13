//TODO:
//gui as sc class or as code below?
//stereo or mono?
//path to soundfile
//where to store specs?  in classfile or in scd file?
//where to store defs?  in classfile or in scd file?
//inbus - test if i can use it among other code (ndefs for example)
//test if something in the gui is memory leaking

(
//--settings
var testPath= thisProcess.nowExecutingPath.dirname+/+"AQf-1/guitar_blues_44100.wav";  //path to soundfile
var inBus= 0;  //for mic and infeedback test sound synth
var width= 640, height= 480;
var palette= QPalette.light;  //dark
var fnt= Font(Font.default, 12);
var plotDur= 0.01;

//--gui
var win= Window("Distortion", Rect(100, 100, width, height));
var testMenu, testButn, defsMenu, defsButn, variMenu, plotView, plotData;
var preLevel, postLevel;
var parameters;
win.view.palette= palette;
win.layout= HLayout(
	VLayout(
		View().background_(palette.button).layout_(VLayout(
			StaticText().string_("TEST SOUND"),
			HLayout(
				testMenu= ListView().background_(palette.button)
				.items_(#[\DtestGuitar, \DtestSoundIn, \DtestInFeedback]),
				testButn= Button().states_([
					["play", palette.buttonText, palette.button],
					["play", palette.buttonText, palette.highlight]
				])
			),
			preLevel= LevelIndicator().minHeight_(14).maxHeight_(14)
			.drawsPeak_(true).warning_(0.85).critical_(0.95)
			.background_(Color.clear).meterColor_(palette.highlight)
		)).maxHeight_(110),
		View().background_(palette.button).layout_(VLayout(
			StaticText().string_("SYNTH DEF"),
			HLayout(
				defsMenu= ListView().background_(palette.button),
				defsButn= Button().states_([
					["bypass", palette.buttonText, palette.button],
					["bypass", palette.buttonText, palette.highlight]
				])
			),
			postLevel= LevelIndicator().minHeight_(14).maxHeight_(14)
			.drawsPeak_(true).warning_(0.85).critical_(0.95)
			.background_(Color.clear).meterColor_(palette.highlight)
		)),
		View().background_(palette.button).layout_(VLayout(
			plotView= UserView().minWidth_(320).minHeight_(100).background_(palette.button)
		))
	),
	VLayout(
		View().background_(palette.button).layout_(VLayout(
			StaticText().string_("SYNTH DEF PARAMETERS").minWidth_(200).maxHeight_(14),
			parameters= GridLayout.rows(),
			StaticText().string_("SYNTH DEF VARIANTS").minWidth_(200).maxHeight_(14),
			variMenu= ListView().minWidth_(200).maxHeight_(100).background_(palette.button)
		)
	))
);
plotView.drawFunc= {
	var pw, ph;
	if(plotData.notNil, {
		pw= plotView.bounds.width;
		ph= plotView.bounds.height*0.85;
		Pen.font= fnt.copy.size_(fnt.size*0.9);

		Pen.translate(0.1*pw, 0.5*ph);
		Pen.strokeColor= Color.grey(0.75);
		Pen.moveTo(Point(0, -0.33*ph));
		Pen.lineTo(Point(0.85*pw, -0.33*ph));
		Pen.moveTo(Point(0, -0.165*ph));
		Pen.lineTo(Point(0.85*pw, -0.165*ph));
		Pen.moveTo(Point(0, 0));
		Pen.lineTo(Point(0.85*pw, 0));
		Pen.moveTo(Point(0, 0.165*ph));
		Pen.lineTo(Point(0.85*pw, 0.165*ph));
		Pen.moveTo(Point(0, 0.33*ph));
		Pen.lineTo(Point(0.85*pw, 0.33*ph));
		Pen.moveTo(Point(0, -0.45*ph));
		Pen.lineTo(Point(0, 0.45*ph));
		Pen.stroke;

		Pen.color= palette.buttonText;
		Pen.stringCenteredIn("1.0", Rect.aboutPoint(Point(-16, -0.33*ph), 20, 20));
		Pen.stringCenteredIn("0.0", Rect.aboutPoint(Point(-16, 0), 20, 20));
		Pen.stringCenteredIn("-1.0", Rect.aboutPoint(Point(-16, 0.33*ph), 20, 20));

		plotData.do{|val, i|
			var x= i.linlin(0, plotData.size-1, 0, 0.85*pw);
			var y= -0.33*ph*val;
			if(i==0, {
				Pen.moveTo(Point(x, y));
			}, {
				Pen.lineTo(Point(x, y));
			});
		};
		Pen.stroke;
		plotData= nil;

		Pen.translate(0.85*0.5*pw, 0.85*0.5*ph);
		Pen.stringCenteredIn("0", Rect.aboutPoint(Point(0, 10), 20, 20), fnt);
		Pen.stringCenteredIn("-5", Rect.aboutPoint(Point(-0.5*0.85*0.5*pw, 10), 20, 20));
		Pen.stringCenteredIn("-10", Rect.aboutPoint(Point(-1*0.85*0.5*pw, 10), 20, 20));
		Pen.stringCenteredIn("-5", Rect.aboutPoint(Point(0.5*0.85*0.5*pw, 10), 20, 20));
		Pen.stringCenteredIn("-10", Rect.aboutPoint(Point(1*0.85*0.5*pw, 10), 20, 20));
	});
};
CmdPeriod.doOnce{win.close};
win.view.children.do{|v| v.font_(fnt)};
win.front;

//--defs
if(SynthDescLib.all.keys.includes(\distortion), {
	defsMenu.items= SynthDescLib.getLib(\distortion).synthDescs.keys.asArray.sort;
}, {
	"No \distortion SynthDescLib found. Make sure SynthDefs are loaded".warn;
});

//--audio
s.waitForBoot{
	var plotBuffer, plotBus, plotDraw;
	var paraDraw, paraList= List.new;
	var variDraw;
	var testSynth, testBuffer, levelPreSynth;
	var defsSynth, levelPostSynth;
	var playBus, mainSynth;
	plotBuffer= Buffer.alloc(s, s.sampleRate*plotDur);
	plotBus= Bus.audio(s, 1);
	playBus= Bus.audio(s, 2);
	testBuffer= Buffer.readChannel(s, testPath, channels:[0]);
	CmdPeriod.doOnce{testBuffer.free; plotBuffer.free; plotBus.free; playBus.free};
	SynthDef(\DtestGuitar, {|bus|
		Out.ar(bus, Pan2.ar(PlayBuf.ar(1, testBuffer, loop:1)*EnvGate()));
	}).add;
	SynthDef(\DtestSoundIn, {|bus, in= 0|
		Out.ar(bus, Pan2.ar(SoundIn.ar(in)*EnvGate()));
	}).add;
	SynthDef(\DtestInFeedback, {|bus, in= 0|
		Out.ar(bus, Pan2.ar(InFeedback.ar(in)*EnvGate()));
	}).add;
	SynthDef(\DtestSoundOut, {|bus, out= 0|
		Out.ar(out, In.ar(bus, 2));
	}).add;
	SynthDef(\DplotSweep, {|bus, dur= 0.01, amp= 10, gate= 0|
		Out.ar(bus, EnvGen.ar(Env(#[-1, 1], [dur]), gate, amp, doneAction:2));
	}).add;
	SynthDef(\DplotRecord, {|bus, buf|
		RecordBuf.ar(In.ar(bus, 2).sum, buf, loop: 0, doneAction:2);
	}).add;
	SynthDef(\DlevelMeter, {|bus, updateRate= 20|
		var z= In.ar(bus, 2).sum;
		var trg= Impulse.kr(updateRate);
		var amp= Amplitude.kr(z, 0.01, 0.5);
		var peak= Peak.kr(z, trg).lag(0, 3);
		SendReply.kr(trg, '/levels', [peak, amp]);
	}).add;
	s.sync;
	mainSynth= Synth(\DtestSoundOut, [\bus, playBus, \out, 0]);

	OSCFunc({|msg|
		var id= msg[1];
		var peak= msg[3];
		var amp= msg[4];
		if(levelPreSynth.notNil and:{id==levelPreSynth.nodeID}, {
			{preLevel.peakLevel_(peak).value_(amp)}.defer;
		}, {
			if(levelPostSynth.notNil and:{id==levelPostSynth.nodeID}, {
				{postLevel.peakLevel_(peak).value_(amp)}.defer;
			});
		});
	}, '/levels', s.addr);

	plotDraw= {|name|
		var lineSynth, tempSynth;
		fork{
			tempSynth= Synth(name, [\bus, plotBus, \preGain, 1, \postGain, 1]);
			lineSynth= Synth(\DplotSweep, [\bus, plotBus, \dur, plotDur]);
			plotDur.wait;  //give time for filters to settle
			s.bind{
				lineSynth.set(\gate, 1);
				Synth(\DplotRecord, [\bus, plotBus, \buf, plotBuffer], tempSynth, \addAfter)
				.onFree{
					tempSynth.free;
					plotBuffer.loadToFloatArray(action:{|arr|
						plotData= arr;
						{plotView.refresh}.defer;
					});
				};
			};
		};
	};

	paraDraw= {|desc|
		parameters.children.do{|l| l.destroy};
		paraList.flat.do{|v| v.remove};
		paraList= List.new;
		if(desc.metadata.notNil, {
			desc.metadata[\specs].keysValuesDo{|key, val|
				Spec.add(key, val);
			};
		});
		desc.controls.do{|cn, i|
			var spec= Spec.specs[cn.name].asSpec;
			var sl;
			var nb= NumberBox().background_(palette.button).maxWidth_(52)
			.normalColor_(palette.buttonText).typingColor_(palette.highlight);
			var st= StaticText().string_(cn.name).font_(fnt).minWidth_(50);
			if(spec.step!=1, {
				nb.decimals= 4;
			});
			if(cn.rate==\control, {
				nb.action= {|view|
					view.value= spec.constrain(view.value);
					sl.value= spec.unmap(view.value);
					defsSynth.set(cn.name, view.value);
				};
				sl= Slider().orientation_(\horizontal).background_(palette.button)
				.maxWidth_(125).maxHeight_(26)
				.action= {|view| nb.valueAction= spec.map(view.value)};
				paraList.add([nb, sl, st]);
			}, {
				if(cn.rate!=\scalar, {"this should not happen".warn});  //debug
				nb.enabled= false;
				paraList.add([nb, st]);
			});
			parameters.add(HLayout(*paraList.last), i);
			nb.valueAction= cn.defaultValue;
		};
	};

	variDraw= {|desc|
		variMenu.items= ["default"];
		if(desc.def.variants.notNil, {
			desc.def.variants.keysDo{|name|
				variMenu.items= variMenu.items++name;
			};
		});
	};

	testMenu.action= {|v|
		if(testButn.value==1, {
			testButn.valueAction_(1);
		});
	};
	testButn.action= {|v|
		if(v.value==1, {
			testSynth.release;
			testSynth= Synth(testMenu.items[testMenu.value], [\in, inBus, \bus, playBus]);
			if(levelPreSynth.notNil, {levelPreSynth.free});
			levelPreSynth= Synth(\DlevelMeter, [\bus, playBus], testSynth, \addAfter);
		}, {
			testSynth.release;
			testSynth= nil;
			levelPreSynth.free;
			levelPreSynth= nil;
		});
	};
	defsButn.action= {|v|
		if(v.value==0, {
			defsSynth.free;
			defsSynth= Synth(defsMenu.items[defsMenu.value], [\bus, playBus], mainSynth, \addBefore);
			if(levelPostSynth.notNil, {levelPostSynth.free});
			levelPostSynth= Synth(\DlevelMeter, [\bus, playBus], defsSynth, \addAfter);
		}, {
			defsSynth.free;
			defsSynth= nil;
			levelPostSynth.free;
			levelPostSynth= nil;
		});
	};
	defsMenu.action= {|v|
		var defName= v.items[v.value];
		var desc= SynthDescLib.getLib(\distortion).synthDescs[defName];
		paraDraw.value(desc);
		variDraw.value(desc);
		defsButn.valueAction_(defsButn.value);
		plotDraw.value(defName);
	};
	defsMenu.valueAction_(0);
	variMenu.action= {|v|
		var defName= defsMenu.items[defsMenu.value];
		var desc= SynthDescLib.getLib(\distortion).synthDescs[defName];
		var varName= variMenu.items[v.value];
		if(varName=="default", {
			desc.controls.do{|cn, i|
                paraList[i][0].valueAction= cn.defaultValue;
			};
		}, {
			desc.def.variants[v.items[v.value]].pairsDo{|key, val|
				paraList.do{|arr, i|
					if(arr[2].string.asSymbol==key, {
						arr[0].valueAction= val;
					});
				};
			};
		});
	};
	variMenu.enterKeyAction= variMenu.action;
};
)