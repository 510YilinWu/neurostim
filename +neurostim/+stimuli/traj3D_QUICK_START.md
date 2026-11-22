# traj3D Quick Start Guide - PTB Integration

## 30-Second Overview

traj3D defines a 3D trajectory → maps to 1D → PTB renders as moving dot

```
3D Trajectory: x(t), y(t), z(t)
         ↓
    Mapping: screen_x = f(x,y,z)
         ↓
   PTB Renders: Dot at (screen_x, 0) each frame
```

## Fastest Way to Run

### 1. One-Liner Setup
```matlab
cd /Users/ywuu0245/PHD-code/demos
c = traj3D_experiment();
c.run();  % Press ESC to stop
```

### 2. What You'll See
- Gray screen with white dot
- Dot moves left-to-right smoothly
- Takes 2 seconds per trial
- 10 trials total

## How It Actually Works

### The Lifecycle

```
START EXPERIMENT
│
├─ beforeExperiment()
│  └─ traj3D calculates coordinate ranges from trajectory
│
├─ FOR each trial
│  │
│  ├─ beforeTrial()
│  │  ├─ Generate full 3D trajectory: [x(t), y(t), z(t)]
│  │  ├─ Map to 1D:  screenX(t) = a·x + b·y + c·z
│  │  └─ Set traj.X = screenX[frame 0]
│  │
│  ├─ FOR each frame (120 times per second)
│  │  │
│  │  ├─ afterFrame()
│  │  │  └─ traj.X = screenX[current frame]
│  │  │
│  │  └─ PTB Draws
│  │     └─ Renders white dot at (traj.X, 0)
│  │
│  └─ afterTrial() [cleanup]
│
└─ DONE - Close window

RESULT: Smooth motion on screen
```

## Essential Code Pattern

### Straight Line (Simplest)

```matlab
% 3 steps:

% 1. Create stimulus in experiment
traj = stimuli.traj3D(c, 'motion');

% 2. Configure trajectory parameters
traj.addProperty('startPos', [0; 0; 0]);
traj.addProperty('velocity', [20; 0; 0]);
traj.trajFun = @stimuli.traj3D.straightLine;

% 3. Configure mapping (3D → 1D)
traj.mappingType = 'weightedSum';
traj.mappingWeights = [1, 0, 0];  % Use only X

% RUN
c.run();
```

### Gabor-Modulated (Oscillating)

```matlab
% Same structure, different trajectory

% 1. Create stimulus
traj = stimuli.traj3D(c, 'motion');

% 2. Configure parameters for Gabor
traj.addProperty('xSpeed', 20);
traj.addProperty('gaborAmp', 5);
traj.addProperty('gaborFreq', 2);
traj.addProperty('gaborSigma', 0.3);
traj.addProperty('gaborPhase', 0);
traj.addProperty('zOffset', 0);
traj.trajFun = @stimuli.traj3D.gaborModulated;

% 3. Configure mapping
traj.mappingType = 'magnitude';
traj.mappingComponents = [2, 3];  % Use Y and Z

% RUN
c.run();
```

## Key Parameters You'll Modify

| Parameter | What It Does | Example |
|-----------|------------|---------|
| `velocity` | Speed and direction in 3D | `[20; 5; 0]` = right+up |
| `xSpeed` | Main motion speed (Gabor only) | `20` |
| `gaborAmp` | Size of oscillation (Gabor only) | `5` |
| `gaborFreq` | Oscillation speed in Hz | `2` = 2 cycles/sec |
| `mappingWeights` | How to combine X, Y, Z | `[1, 0, 0]` = use X only |
| `mappingType` | Combination method | `'weightedSum'` or `'magnitude'` |
| `on` | When stimulus starts (ms) | `0` = at trial start |
| `duration` | How long stimulus shows (ms) | `2000` = 2 seconds |

## Visualization (Do This First!)

Before running, check what it looks like:

```matlab
% Visualize the trajectory
figs = visualizeTraj3D(...
    @stimuli.traj3D.straightLine, ...
    {[0;0;0], [20;0;0], 240, 120}, ...
    240, 120, ...
    'weightedSum', [1,0,0], struct()
);

% You'll see 5 plots:
% 1. 3D path (does it look right?)
% 2. XY view
% 3. XZ view
% 4. YZ view
% 5. Screen X vs time (final 1D motion)
```

If plots look wrong → fix parameters before running experiment.

## Troubleshooting in 10 Seconds

| Problem | Check | Fix |
|---------|-------|-----|
| Dot doesn't move | `traj.trajFun` | Set it: `@stimuli.traj3D.straightLine` |
| Motion is frozen | `traj.velocity` or `traj.xSpeed` | Make it non-zero |
| Motion looks wrong | `traj.mappingWeights` | Use `[1,0,0]` if only X should move |
| Dot off-screen | `traj.coordRangeX` | Reduce velocity or expand range |
| Too slow | `traj.screenScale` | Increase: `2.0` |
| Too fast | `traj.screenScale` | Decrease: `0.5` |

## Common Modifications

### Change motion speed
```matlab
traj.velocity = [40; 0; 0];  % Faster
% or
traj.xSpeed = 40;  % For Gabor
```

### Add oscillation to straight line
Switch to Gabor instead of straightLine

### Change stimulus color
```matlab
traj.color = [1, 0, 0];  % Red
traj.color = [0, 1, 0];  % Green
traj.color = [1, 1, 0];  % Yellow
```

### Change stimulus size
```matlab
traj.scale.x = 2;  % Twice as wide
traj.scale.y = 2;  % Twice as tall
```

### Run more trials
```matlab
c.nrTrials = 50;  % Instead of 10
```

### Different trajectory for each trial (Design)
```matlab
% Add condition dimension
d = design('speed', [10, 20, 30]);
c.addDesign(d);

% Vary trajectory with condition
traj.velocity = @(cic) [cic.condition * 10; 0; 0];
```

## The Update Chain (for understanding)

```
Each Frame:
  1. Neurostim calls traj.afterFrame()
  2. traj.afterFrame() updates traj.X
  3. PTB reads traj.X
  4. PTB draws dot at (traj.X, traj.Y) with traj.color
  5. Screen flips
  6. Repeat

Result: smooth motion at screen refresh rate (~120 Hz)
```

## PTB Screen Coordinates

```
          Y
          ↑
          |
    (-800,0) -------- (800,0)  ← Screen Center
          |
    ← X →
```

Default: 1600 pixels wide (±800), origin at center

Motion along X (horizontal) looks like:
- X = -500 → Dot on left
- X = 0 → Dot in center
- X = 500 → Dot on right

## File Organization

```
Your work:
  /Users/ywuu0245/PHD-code/
  ├── demos/
  │   └── traj3D_experiment.m ← Edit this to modify
  │
  └── neurostim/
      └── +neurostim/+stimuli/
          ├── traj3D.m ← Plugin code (don't edit unless extending)
          ├── traj3D_README.md ← Full documentation
          ├── traj3D_PTB_INTEGRATION.md ← Detailed PTB guide
          └── visualizeTraj3D.m ← Visualization tool
```

## Copy-Paste Template

```matlab
function c = my_experiment()
    import neurostim.*

    % Setup
    c = cic.main();
    c.screen.type = 'PTB';
    c.screen.color.background = [0.5, 0.5, 0.5];
    c.trialDuration = 2000;
    c.nrTrials = 5;

    % Create stimulus
    traj = stimuli.traj3D(c, 'motion');
    traj.color = [1, 1, 1];
    traj.on = 0;
    traj.duration = 2000;

    % Straight line trajectory
    traj.addProperty('startPos', [0; 0; 0]);
    traj.addProperty('velocity', [20; 0; 0]);
    traj.trajFun = @stimuli.traj3D.straightLine;

    % Mapping
    traj.mappingType = 'weightedSum';
    traj.mappingWeights = [1, 0, 0];
    traj.autoCoordRange = true;

    % Run (uncomment to execute)
    % c.run();
end

% USAGE:
% c = my_experiment();
% c.run();
```

## Next: More Complex Stuff

Once this works, you can:
1. Add multiple conditions (use `design()`)
2. Add responses (use `behaviors.keyResponse()`)
3. Add eye tracking (use `plugins.eyelink`)
4. Create custom trajectories (write `function traj = ...`)
5. Log data and analyze

But first: **get basic motion working!**

---

**Remember:** Always visualize with `visualizeTraj3D()` before running the full experiment!
