(
// specify directory with samples
var currentDir = PathName(thisProcess.nowExecutingPath).pathOnly;
var sampleDir = currentDir +/+ "soundfiles";
var confFile = currentDir +/+ "conf.scd";
var walk, walkWait=5;
var win, palette, panel, windowHeight, windowWidth,
viewMaster, viewConn, elemWidth;
var group, outSynth, soundIn, createGroup, playSynth;
var meterView;
var cmdPeriodFunc;
var conf, params;
var specs = (
	freq: \freq.asSpec,
	lfreq: ControlSpec(0.1, 10, \lin, 0.1, 0.5, "Hz"),
	cutoff: \freq.asSpec,
	cutoffmin: \freq.asSpec,
	cutoffmax: \freq.asSpec,
	delay: \delay.asSpec,
	detune: \detune.asSpec,
	rate: \rate.asSpec,
	audiobus: \audiobus.asSpec,
	controlbus: \controlbus.asSpec,
	offset: \midinote.asSpec,
	envtime: ControlSpec(1, 1000, \lin, 1, 500, "ms"),
	decaytime: ControlSpec(0.1, 10, \exp, 0.01, 4, "s"),
	rq: \rq.asSpec,
	insanity: ControlSpec(-5.0, 0.0, \lin, 0.01, -1.8),
	level: \db.asSpec,
	amp: \db.asSpec,
	gain: ControlSpec(0.1, 500, \exp, 0.1, 1, "*"),
);
var factory = [
	(
		synth: "looper_mono",
		width: 200,
		out: 6,
		params: [
			// (
			// 	name: \walk,
			// 	val: false,
			// 	style: \checkBox,
			// 	states: ["->", "(1)"],
			// 	trig: [walk.play, walk.stop],
			// 	scale: 0.5
			// ),
			(
				name: \bufnum,
				val: 0,
				style: \listView,
				items: sampleLabels.asArray,
				scale: 0.6,
			),
			(
				name: \level,
				spec: \db.asSpec,
				val: 0,
				style: \slider,
				layout: \vert,
				scale: 0.8
			),
		]
	),
	(
		synth: "smoozi",
		width: 150,
		in: 6,
		out: 5,
		params: [
			(
				name: \factor,
				spec: ControlSpec(1, 0.00001, \exp, 0.00001, 0.8),
				val: 0.8,
				style: \knob,
				size: \XXL
			),
		]
	),
	(
		synth: "compressor_mb",
		width: 430,
		in: 5,
		out: 4,
		params: [

			// TODO: solve freqs with Plotter?
			// (
			//     name: \plotter,
			//     style: \plotter,
			//     value: [
			//         [0, 1, 1.5, 0],
			//         [0, 1]
			//     ]
			// ),

			// Low band
			(
				name: \freqLowPass,
				label: "LOW: freq",
				spec: \freq.asSpec,
				val: 245,
				style: \knob,
				size: \M
			),
			(
				name: \threshLow,
				label: "thresh",
				spec: \db.asSpec,
				val: -60,
				style: \knob,
				size: \M
			),
			(
				name: \ratioLow,
				label: "ratio x:1",
				spec: ControlSpec(1.1, 5, \lin, 0.1, 2),
				val: 2,
				style: \knob,
				size: \M
			),
			(
				name: \clampTimeLow,
				label: "clamp",
				spec: ControlSpec(0.0001, 1, 'exp', 0.0001, 0.3, " sec"),
				val: 0.035,
				style: \knob,
				size: \M
			),
			(
				name: \relaxTimeLow,
				label: "relax",
				spec: ControlSpec(0.0001, 1, 'exp', 0.0001, 0.3, " sec"),
				val: 0.385,
				style: \knob,
				size: \M
			),
			(
				name: \gainLow,
				label: "LOW: gain",
				spec: ControlSpec(-inf, 12.0, 'db', 0.0, -inf, " dB"),
				val: 0,
				style: \knob,
				size: \M
			),

			// Mid band
			(
				name: \freqBandPass,
				label: "MID: center",
				spec: \freq.asSpec,
				val: 5463,
				style: \knob,
				size: \M
			),
			(
				name: \threshMid,
				label: "thresh",
				spec: \db.asSpec,
				val: -60,
				style: \knob,
				size: \M
			),
			(
				name: \ratioMid,
				label: "ratio x:1",
				spec: ControlSpec(1.1, 5, \lin, 0.1, 2),
				val: 2,
				style: \knob,
				size: \M
			),
			(
				name: \clampTimeMid,
				label: "clamp",
				spec: ControlSpec(0.0001, 1, 'exp', 0.0001, 0.3, " sec"),
				val: 0.035,
				style: \knob,
				size: \M
			),
			(
				name: \relaxTimeMid,
				label: "relax",
				spec: ControlSpec(0.0001, 1, 'exp', 0.0001, 0.3, " sec"),
				val: 0.385,
				style: \knob,
				size: \M
			),
			(
				name: \gainMid,
				label: "MID: gain",
				spec: ControlSpec(-inf, 12.0, 'db', 0.0, -inf, " dB"),
				val: 0,
				style: \knob,
				size: \M
			),

			// High band
			(
				name: \freqBandPass,
				label: "HIGH: freq",
				spec: \freq.asSpec,
				val: 11172,
				style: \knob,
				size: \M
			),
			(
				name: \threshHigh,
				label: "thresh",
				spec: \db.asSpec,
				val: -60,
				style: \knob,
				size: \M
			),
			(
				name: \ratioHigh,
				label: "ratio x:1",
				spec: ControlSpec(1.1, 5, \lin, 0.1, 2),
				val: 2,
				style: \knob,
				size: \M
			),
			(
				name: \clampTimeHigh,
				label: "clamp",
				spec: ControlSpec(0.0001, 1, 'exp', 0.0001, 0.3, " sec"),
				val: 0.035,
				style: \knob,
				size: \M
			),
			(
				name: \relaxTimeHigh,
				label: "relax",
				spec: ControlSpec(0.0001, 1, 'exp', 0.0001, 0.3, " sec"),
				val: 0.385,
				style: \knob,
				size: \M
			),
			(
				name: \gainHigh,
				label: "HIGH: gain",
				spec: ControlSpec(-inf, 12.0, 'db', 0.0, -inf, " dB"),
				val: 0,
				style: \knob,
				size: \M
			),

			(
				name: \level,
				label: "Master gain",
				spec: ControlSpec(-inf, 12.0, 'db', 0.0, -inf, " dB"),
				val: 0,
				style: \knob,
				size: \L
			),
		]
	),
	(
		synth: "distort",
		width: 300,
		in: 6,
		out: 0,
		params: [
			(
				name: \gain,
				label: "PRE gain",
				spec: specs[\gain],
				val: 40,
				style: \knob,
				size: \L
			),
			(
				name: \cutoff,
				label: "cutoff",
				spec: specs[\cutoff],
				val: 8000,
				style: \knob,
				size: \M
			),
			(
				name: \insanity,
				label: "insanity",
				spec: specs[\insanity],
				val: -1.8,
				style: \knob,
				size: \M
			),
			(
				name: \wet,
				spec: \unipolar.asSpec,
				val: 0.8,
				style: \knob,
				size: \L
			),
			(
				name: \level,
				spec: \db.asSpec,
				val: -27.958800173441,
				style: \knob,
				size: \L
			),
		]
	),
	(
		synth: "fuzz",
		width: 280,
		in: 6,
		out: 0,
		params: [
			(
				name: 'gain',
				label: 'PRE gain',
				spec: ControlSpec(1, 100, \exp, 0.1, 80, "*"),
				val: 80,
				style: 'knob',
				size: 'L'
			),
			(
				name: 'amount',
				label: 'amount',
				spec: ControlSpec(0.01, 1, 'lin', 0.01, 0.5),
				val: -1.8,
				style: 'knob',
				size: 'L'
			),
			(
				name: 'wet',
				spec: ControlSpec(0, 1, 'linear', 0.0, 0, ""),
				val: 0.9,
				style: 'knob',
				size: 'M'
			),
			(
				name: 'level',
				spec: ControlSpec(-inf, 0.0, 'db', 0.0, -inf, " dB"),
				val: -12,
				style: 'knob',
				size: 'M'
			),
		]
	),
	(
		synth: "echorz",
		width: 340,
		in: 6,
		out: 0,
		params: [
			(
				name: \delaypre,
				label: "delay PRE",
				spec: specs[\delay],
				val: 0.01,
				style: \knob,
				size: \L
			),
			(
				name: \delaypost,
				label: "delay POST",
				spec: specs[\delay],
				val: 0.04,
				style: \knob,
				size: \L
			),
			(
				name: \decay,
				spec: specs[\decaytime],
				val: 4,
				style: \knob,
				size: \L
			),
			(
				name: \wet,
				spec: \unipolar.asSpec,
				val: 0.8,
				style: \knob,
				size: \M
			),
			(
				name: \level,
				spec: \db.asSpec,
				val: -27.958800173441,
				style: \knob,
				size: \M
			),
		]
	),
];
var resend = { |node, params|
	if (node.isNil.not) {
		params = params ? [ ];
		params.pairsDo { |name, val|
			node.set(name, val)
		};
	}
};
var transparent=Color.grey(alpha:0.01),
panelColor=Color.black,
techColor=Color.green(0.5),
font=Font("Monaco", 14),
fontSmall=Font("Monaco", 10),
fontMedium=Font("Monaco", 12),
fontLarge=Font("Monaco", 14),
fontLarge1=Font("Monaco", 18),
fontGiant=Font("Monaco", 24),
fontColor=Color.white;

// GUI: elements
var paneWidth = { |par, scale=1| (par.bounds.width * scale - 10).floor };
var paneHeight = { |par, scale=1| (par.bounds.height * scale - 10).floor };
var compView = { |par, bounds, color|
	CompositeView(par, bounds).background_(color ? panelColor);
};
var compViewFlow = { |par, bounds, color, margin, gap|
	var vw;
	vw = compView.(par, bounds, color);
	vw.decorator = FlowLayout(vw.bounds, margin ? 1@1, gap ? 1@1);
	vw
};
var dropdown = { |par, label, items, action, initVal=0, initAction=false, scale=1|
	var ezpum, labelWidth=0;
	if (label.isNil.not) { labelWidth = label.size * 9};
	ezpum = EZPopUpMenu(par,
		bounds: paneWidth.(par, scale).max(50)@30,
		label: label,
		items: items,
		globalAction: action,
		initVal: initVal,
		initAction: initAction,
		labelWidth: labelWidth
	)
	.font_(font);
	ezpum.setColors(
		stringBackground:Color.black,
		stringColor:fontColor,
		menuBackground: Color.black,
		menuStringColor:fontColor,
		background:Color.black
	);
	ezpum
};
var sText = { |par, string, stringColor, stringFont, width, scaleW, scaleH|
	// Warning: if `width` (constant) is given, `scaleW` is being ignored.
	var st, height;
	if (scaleH.isNil) {
		height = 20;
	} {
		height = paneHeight.(par, scaleH);
	};
	if (width.isNil) {
		width = paneWidth.(par, (scaleW ? 0.5).asFloat)
	};
	st = StaticText(par, width@height);
	st.string = string;
	st.font = stringFont ? font;
	st.stringColor = stringColor ? fontColor;
	st
};
var plotter = { |par, value, scaleW=1, scaleH=1|
	var width = paneWidth.(par, scaleW);
	var height = paneHeight.(par, scaleH);
	var plt = Plotter("plot", Rect(0, 0, width, height), parent: par)
	.value_(value)
	.superpose_(true);
	plt
};
var slider = { |par, label, spec, action, initVal=0, layout='horz', scale=1|
	var ezs, bounds;
	bounds = paneWidth.(par, scale)@30;
	label = format(" % ", label).asString;
	if (layout != 'horz') { bounds = 30@paneHeight.(par, scale) };
	ezs = EZSlider(par, bounds,
		label, spec,
		{ |ez| action.(ez.value) }, initVal,
		numberWidth:45,
		layout:layout,
	)
	.font_(fontSmall);
	ezs.numberView.canFocus = false;
	ezs.sliderView.canFocus = false;
	ezs.setColors(
		stringColor: fontColor,
		sliderBackground: Color.grey(alpha:0.3),
		numBackground: Color.grey(alpha:0.5),
		numNormalColor: Color.yellow,
		background: transparent
	);
};
var knob = { |par, label, spec, action, initVal=0, layout='vert', width=72|
	var kbob, stepString, height=width*1.4;
	label = format(" % ", label).asString;
	kbob = EZKnob(par,
		width@height,
		label,
		spec,
		{ |ez| action.(ez.value) },
		initVal,
		layout: layout
	)
	.font_(fontSmall)
	.setColors(
		transparent,
		Color.white,
		Color.grey,
		Color.white,
		Color.yellow,
		nil,
		nil,
		transparent
	);
	kbob.numberView.maxDecimals = spec.step.asString.split($\.).last.size();
	kbob;
};
var checkBox = { |par, states|
	Button(panel, 30@40)
	.states_([
		[states[0], fontColor, techColor],
		[states[1], Color.white, Color.new255(220, 176, 70)]
	])
	.font_(fontMedium)
};
var listView = { |par, items, action, initVal=0, scaleH=1, scaleW=1|
	var labelWidth=0, listView;
	listView = ListView(par, paneWidth.(par, scaleW)@paneHeight.(par, scaleH))
	.items_(items)
	.action_(action)
	.font_(fontMedium)
	.background_(transparent)
	.stringColor_(fontColor)
	.hiliteColor_(Color.grey(alpha:0.6))
	.selectedStringColor_(Color.white);
	listView
};
var samples=List.new, sampleLabels=List.new, samplesDD;
var groupTask, intLevelMax=20;

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

// create group and synths
"-> Creating basic group...".postln;
group = Group.new;

"-> Loading synth definitions...".postln;
if (this.executeFile(currentDir +/+ "synthdef.scd").isNil.not) {
	"-> Catching audiofrom external input...".postln;
	soundIn = Synth.head(group, "sound_in", [\in, 0, \out, 10]);

	"-> Creating master output synth...".postln;
	outSynth = Synth.tail(group, "output_stereo");
	postf("OK\n\n")
} {
	postf("ERROR: Cannot load!\n\n")
};

// GUI skin
GUI.skins.plot.gridLinePattern = FloatArray[1, 0];
GUI.skins.plot.fontColor = Color(0.5, 1, 0);
GUI.skins.plot.gridColorX = Color.yellow(0.5);
GUI.skins.plot.gridColorY = Color.yellow(0.5);
GUI.skins.plot.background = Color.black;
GUI.skins.plot.plotColor = (10..0).normalize(0.1, 1).collect { |i| Color.rand(i) };
GUI.skins.plot.labelX = "X";
GUI.skins.plot.labelY = "Y";

// main effect plate config
"-> Loading conf...".postln;
try { // to load from conf file
	conf = File(confFile, "r").readAllString.interpret;
	postf("OK\n\n");
} {
	postf("ERROR: Cannot load! Using factory settings...\n\n");
	conf = factory;
};

// fill newly added controls
factory.do { |unit, i|
	unit.params.do { |param, j|
		if (conf[i][\params][j][\name] != param[\name]) {
			conf[i][\params].insert(j, param)
		}
	};
};

// add samples items to controls
conf.do { |unit|
	if (unit[\synth] == "looper_mono") {
		unit[\params].do { |pm|
			if (pm[\name] == \bufnum) {
				pm[\items] = sampleLabels.asArray
			}
		}
	}
};

// make the window
windowHeight = 650;
windowWidth = 1600; //Window.screenBounds.width;
win = Window("control panel",
	Rect(0, Window.screenBounds.height-windowHeight, windowWidth, windowHeight),
	resizable:false
);
win.front; // make window visible and front window.
win.view.decorator = FlowLayout(win.view.bounds);
win.view.decorator.gap=1@1;
palette = QPalette.dark;
palette.setColor(Color.grey(0.2), \window);
win.view.palette = palette;

viewMaster = compViewFlow.(win, 360@200);
viewConn = compViewFlow.(win, (windowWidth-viewMaster.bounds.width-(5*conf.size))@200);

// internal levels
meterView = EntroServerMeterView(Server.default, viewMaster, 0@0, viewMaster.bounds.height);

// Play samples one after another with pause `walkWait`
walk = Task({
	var dur;
	samples.do { |buf, i|
		dur = buf.numFrames / s.sampleRate;
		{
			conf[0][\list].valueAction_(i);
			conf[0][\trig].value_(1);
			playSynth.(conf[0], 1, 0);
		}.defer;
		dur.wait;

		{conf[0][\trig].value_(0)}.defer;
		walkWait.wait;
	}
});
Button(viewConn, 50@40) //  temporarily to viewConn
.states_([
	[">>", fontColor, techColor],
	["||", Color.white, Color.red(0.7)]
])
.font_(fontLarge)
.action = {|view|
	if (view.value == 1) {
		walk.play;
	} {
		conf[0][\trig].valueAction_(0);
		walk.pause;
	};
};
Button(viewConn, 70@40) //  temporarily to viewConn
.states_([
	["STOP", fontColor, techColor],
])
.font_(fontLarge)
.action = {|view|
	conf[0][\trig].valueAction_(0);
	walk.stop;
	walk.reset;
};

playSynth = {|unit, act=1, loop=1|
	if (act == 1) {
		params = all {: [p[\name], p[\val]], p <- unit.params}.flatten;
		try {
			params = params ++ [\in, unit[\in], \out, unit[\out], \loop, loop];
		};
		// start sound
		params.asArray.postln;
		unit[\node] = Synth.head(group, unit[\synth], params.asArray);
	} {
		// set gate to zero to cause envelope to release
		unit[\node].set(\gate, 0);
		unit[\node] = nil;
	};
};


// effects rack
conf.do { |unit, i|
	elemWidth = (unit[\synth].size*10) + 200;
	panel = compViewFlow.(win,
		unit[\width]@(win.bounds.height-viewMaster.bounds.height),
		gap: 5, margin: 10
	);

	// ON/OFF button
	unit[\trig] = Button(panel, (unit[\synth].size*10)@40)
	.states_([
		[unit[\synth], fontColor, techColor],
		[unit[\synth], Color.white, Color.red(0.7)]
	])
	.font_(fontLarge)
	.action = {|view|
		playSynth.(unit, view.value)
	};
	// Effect bypass
	if (unit[\in].isNil.not && unit[\out].isNil.not) {
		Button(panel, 30@40)
		.states_([
			["B", fontColor, techColor],
			["B", Color.white, Color.new255(220, 176, 70)]
		])
		.font_(fontLarge)
		.action = {|view|
			if (view.value == 1) {
				unit[\node].set(\wet, 0);
			} {
				unit.params.do { |parm|
					unit[\node].set(parm[\name], parm[\val]);
				};
				unit[\node].set(\wet, 1)
			};
		};
	};
	// Channel IN
	if (unit[\in].isNil.not) {
		sText.(panel, "I", stringFont: fontLarge, width: 10, scaleH: 0.12);
		dropdown.(
			panel,
			items: Array.fill(intLevelMax+1, _.value),
			initVal: unit[\in],
			action: { |element|
				unit[\in] = element.value;
				resend.(unit[\node], [\in, element.value]);
			},
			scale: 0.17
		);
	};
	// Channel OUT
	sText.(panel, "O", stringFont: fontLarge, width: 10, scaleH: 0.12);
	dropdown.(
		panel,
		items: Array.fill(intLevelMax+1, _.value),
		initVal: unit[\out],
		action: { |element|
			unit[\out] = element.value;
			resend.(unit[\node], [\out, element.value]);
		},
		scale: 0.17
	);

	// unit params
	panel.decorator.nextLine;
	unit[\params].do { |param, j|
		param[\style].switch(
			\plotter, {
				plotter.(panel, value: param[\value], scaleH:0.3)
			},
			\slider, {
				slider.(panel,
					param[\label] ? param[\name],
					param[\spec],
					{ |elt|
						param[\val] = elt.value;
						resend.(unit[\node], [param[\name], elt.value]);
					},
					initVal: param[\val],
					layout: param[\layout] ? \horz,
					scale: param[\scale] ? (unit[\params].size.reciprocal)
				)
			},
			\knob, {
				elemWidth = param[\size].switch(
					\XXL, { 120 },
					\XL, { 80 },
					\L, { 72 },
					\M, { 60 },
					\S, { 50 },
					\XS, { 38 },
					{ 72 }
				);
				knob.(panel,
					param[\label] ? param[\name],
					param[\spec],
					{ |elt|
						param[\val] = elt.value;
						resend.(unit[\node], [param[\name], elt.value]);
					},
					initVal: param[\val],
					width: elemWidth
					// scale: param[\scale] ? (unit[\params].size.reciprocal)
				)
			},
			\listView, {
				unit[\list] = listView.(panel,
					param[\items],
					{ |elt|
						param[\val] = elt.value;
						resend.(unit[\node], [param[\name], samples[elt.value].bufnum]);
					},
					param[\val],
					scaleH: 0.8, scaleW: param[\scale]
				)
			},
			\checkBox, {
				checkBox.(panel, unit[\params][\states])
			}
		)
	}
};


// set start button to zero upon a cmd-period
cmdPeriodFunc = {
	meterView.stop;
	win.close;
};
CmdPeriod.add(cmdPeriodFunc);

// stop the sound when window closes and remove cmdPeriodFunc.
win.onClose = {
	outSynth.free;
	soundIn.free;
	outSynth = nil;
	group.free;
	group = nil;
	samples.do { |b| b.free};

	conf.do { |item|
		item.removeAt(\node)
	};
	confFile = File.new(confFile, "w");
	confFile.write(conf.asCompileString);
	confFile.close;

	CmdPeriod.remove(cmdPeriodFunc);
};
)
