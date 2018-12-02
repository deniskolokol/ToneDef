(
var win, palette, panel, windowHeight, windowWidth,
    viewMaster, viewConn, elemWidth;
var group, outSynth, createGroup;
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
    level: \db.asSpec,
    amp: \db.asSpec,
    gain: ControlSpec(0.1, 500, \exp, 0.1, 1, "*"),
);
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
    var height = width * 1.4;
    label = format(" % ", label).asString;
    EZKnob(par,
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
    )
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


// read test samples
var currentDir = PathName(thisProcess.nowExecutingPath).pathOnly;
var sampleDir = currentDir +/+ "test_sounds";
var confFile = currentDir +/+ "plate.conf";
var samples=List.new, sampleLabels=List.new, samplesDD;
var groupTask, intLevelMax=20;

"-> Reading test samples...".postln;
PathName.new(sampleDir).entries.do { |f, i|
    samples.add(Buffer.readChannel(s, f.fullPath, channels: [0]));
    sampleLabels.add(f.fileName);
};

// create group and synths
"-> Creating basic group...".postln;
group = Group.new;

"-> Loading synth definitions...".postln;
if (this.executeFile(currentDir +/+ "synthdef.scd").isNil.not) {
    "-> Creating master output synth...".postln;
    outSynth = Synth.tail(group, "output_stereo");
    postf("OK\n\n")
} {
    postf("ERROR: Cannot load!\n\n")
};

// main effect plate config
"-> Loading conf...".postln;
try { // to load from conf file
    conf = File(confFile, "r").readAllString.interpret;
    postf("OK\n\n");
} {
    postf("ERROR: Cannot load! Using factory settings...\n\n");
    conf = [
        (
            synth: "looper_mono",
            width: 200,
            out: 6,
            params: [
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
            synth: "compressor",
            width: 360,
            in: 5,
            out: 4,
            params: [
                (
                    name: \thresh,
                    spec: \db.asSpec,
                    val: -60,
                    style: \knob,
                    size: \L
                ),
                (
                    name: \ratio,
                    label: "ratio",
                    spec: ControlSpec(1.1, 5, \lin, 0.1, 2),
                    val: 2,
                    style: \knob,
                    size: \L
                ),
                (
                    name: \clampTime,
                    label: "clamp time",
                    spec: ControlSpec(0.01, 1.00, \exp, 0.01, 0.01),
                    val: 0.01,
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
            synth: "echorz",
            width: 400,
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
    ]
};

// make the window
windowHeight = 500;
// windowWidth = 360 + sum(all {: l[\width], l <- conf}) + (5*conf.size);
windowWidth = Window.screenBounds.width;
win = Window("control panel",
    Rect(0, Window.screenBounds.height-windowHeight, windowWidth, windowHeight),
    // resizable:false, border:false
);
win.front; // make window visible and front window.
win.view.decorator = FlowLayout(win.view.bounds);
win.view.decorator.gap=1@1;
palette = QPalette.dark;
palette.setColor(Color.grey, \window);
win.view.palette = palette;

viewMaster = compViewFlow.(win, 360@200);
viewConn = compViewFlow.(win, (windowWidth-viewMaster.bounds.width-(5*conf.size))@200);

// internal levels
meterView = EntroServerMeterView(Server.default, viewMaster, 0@0, viewMaster.bounds.height);

// effects rack
conf.do { |unit, i|
    elemWidth = (unit[\synth].size*10) + 200;
    panel = compViewFlow.(win,
        elemWidth@(win.bounds.height-viewMaster.bounds.height),
        gap: 5, margin: 10
    );

    // ON/OFF button
    [unit[\synth], unit[\synth].size].postln;
    Button(panel, (unit[\synth].size*10)@40)
    .states_([
        [unit[\synth], fontColor, techColor],
        [unit[\synth], Color.white, Color.red(0.7)]
    ])
    .font_(fontLarge)
    .action = {|view|
        if (view.value == 1) {
            params = all {: [p[\name], p[\val]], p <- unit.params}.flatten;
            try {
                params = params ++ [\in, unit[\in], \out, unit[\out]];
            };
            // start sound
            unit[\node] = Synth.before(outSynth, unit[\synth], params.asArray);
        } {
            // set gate to zero to cause envelope to release
            unit[\node].set(\gate, 0);
            unit[\node] = nil;
        };
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
                }
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
                listView.(panel,
                    param[\items],
                    { |elt|
                        param[\val] = elt.value;
                        resend.(unit[\node], [param[\name], samples[elt.value].bufnum]);
                    },
                    param[\val],
                    scaleH: 0.8, scaleW: param[\scale]
                )
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
    outSynth = nil;
    group.free;
    group = nil;
    samples.do { |b| b.free};

    conf.do { |item|
        item.removeAt(\node)
    };
    conf.postln;
    confFile = File.new(confFile, "w");
    confFile.write(conf.asCompileString);
    confFile.close;

    CmdPeriod.remove(cmdPeriodFunc);
};
)