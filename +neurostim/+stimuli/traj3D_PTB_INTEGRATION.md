# traj3D Integration with Psychotoolbox (PTB)

## Overview

The traj3D stimulus integrates seamlessly with Psychotoolbox through neurostim's rendering pipeline. PTB automatically renders the stimulus each frame based on the X and Y coordinates that traj3D updates.

## How It Works: The Rendering Pipeline

### 1. Neurostim Lifecycle
Your experiment runs through these phases:

```
beforeExperiment()
├─ traj3D auto-calculates coordinate ranges from trajectory
│
[For each trial]
├─ beforeTrial()
│  ├─ Generate 3D trajectory: [x(t), y(t), z(t)] for all frames
│  └─ Map 3D to 1D: screenX = f(x,y,z)
│  └─ Set initial position: traj.X
│
├─ [For each frame]
│  ├─ afterFrame()
│  │  └─ Update traj.X with current frame's screen position
│  │
│  └─ PTB Renders
│     ├─ Draw stimulus at (traj.X, traj.Y)
│     ├─ Use traj.color
│     └─ Use traj.scale for size
```

### 2. Key Properties

The stimulus uses these properties for rendering:
- **traj.X** - Horizontal screen position (updated each frame)
- **traj.Y** - Vertical position (always 0 for this stimulus)
- **traj.color** - RGB color (set once, fixed)
- **traj.scale** - Size on screen
- **traj.on** - When stimulus appears (milliseconds)
- **traj.duration** - How long stimulus displays (milliseconds)

### 3. The Update Loop

```matlab
% Frame 0 (initialization)
traj.X = initPos or screenTraj(1)
traj.Y = 0

% Frame 1, 2, 3, ... (motion)
for frame = 1:nFrames
    traj.X = screenTraj(frame)  % Updated in afterFrame()
    traj.Y = 0
    % PTB renders dot at (X, Y)
end
```

## Quick Start: Running Your First Experiment

### Step 1: Set Up Paths
```matlab
% Add neurostim to MATLAB path
addpath('/Users/ywuu0245/PHD-code/neurostim');
addpath('/Users/ywuu0245/PHD-code');
```

### Step 2: Run the Example Experiment
```matlab
% Navigate to demos folder
cd /Users/ywuu0245/PHD-code/demos

% Run the example
c = traj3D_experiment();

% This sets up the experiment. To actually start it:
c.run();

% Press ESC to stop
```

### Step 3: What You'll See
- Gray background
- White dot moving horizontally from left to right
- Motion follows the defined trajectory (straight line in the example)
- 10 trials, each 2 seconds long
- Black fixation point at center (optional)

## Configuration Guide

### Minimal Setup (Straight Line Motion)

```matlab
import neurostim.*

% Create experiment
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

% Configure trajectory
traj.addProperty('startPos', [0; 0; 0]);
traj.addProperty('velocity', [20; 0; 0]);
traj.trajFun = @stimuli.traj3D.straightLine;

% Configure mapping
traj.mappingType = 'weightedSum';
traj.mappingWeights = [1, 0, 0];
traj.autoCoordRange = true;

% Run
c.run();
```

### With Gabor-Modulated Trajectory

```matlab
% ... (setup as above) ...

% Configure Gabor trajectory
traj.addProperty('xSpeed', 20);
traj.addProperty('gaborAmp', 5);
traj.addProperty('gaborFreq', 2);
traj.addProperty('gaborSigma', 0.3);
traj.addProperty('gaborPhase', 0);
traj.addProperty('zOffset', 0);
traj.trajFun = @stimuli.traj3D.gaborModulated;

% Map using magnitude
traj.mappingType = 'magnitude';
traj.mappingComponents = [2, 3];

% Run
c.run();
```

### With Conditions (Using Design)

```matlab
% Create conditions with different velocities
d = design('speed', [10, 20, 30]);  % Three speeds
c.addDesign(d);

% Vary velocity across conditions
traj.velocity = @(cic) [cic.condition*10; 0; 0];

% Or vary mapping weights
traj.mappingWeights = @(cic) [1-0.1*cic.condition, 0.1*cic.condition, 0];

c.run();
```

## Visual Properties

### Changing Stimulus Appearance

```matlab
% Color
traj.color = [1, 0, 0];     % Red dot
traj.color = [0, 1, 0];     % Green dot
traj.color = [1, 1, 0];     % Yellow dot

% Size (larger = wider scale)
traj.scale.x = 2;           % 2x larger in x
traj.scale.y = 2;           % 2x larger in y
% For dot: usually keep x = y

% Opacity (if supported)
traj.opacity = 0.5;         % Semi-transparent (not all PTB modes support)

% Position offsets
traj.X = 10;                % Shift right by 10 units (but traj3D updates this)
traj.Y = 5;                 % Shift up by 5 units (not recommended - breaks motion axis)
```

### Adding Additional Stimuli

```matlab
% Add fixation point
fix = stimuli.fixation(c, 'fix');
fix.color = [0, 0, 0];
fix.size = 0.5;
fix.on = 0;
fix.duration = Inf;

% Add background grid
% (would need custom stimulus or background image)
```

## Trajectory Verification Before Running

**IMPORTANT**: Always visualize before running full experiment

```matlab
% 1. Visualize the trajectory
figs = neurostim.stimuli.visualizeTraj3D(...
    @neurostim.stimuli.traj3D.straightLine, ...
    {[0;0;0], [20;0;0], 240, 120}, ...  % trajectory parameters
    240, ...                            % nFr
    120, ...                            % frameRate
    'weightedSum', ...                  % mappingType
    [1, 0, 0], ...                      % mappingWeights
    struct() ...                        % coordRanges (auto-calculated)
);

% 2. Check the 5 plots that appear:
%    - 3D: Is the trajectory what you expect?
%    - XY/XZ/YZ: Do projections look correct?
%    - Screen X: Does the 1D motion look right?

% 3. If satisfied, run the experiment
% If not, adjust parameters and visualize again
```

## Common Issues and Solutions

### Issue 1: Stimulus doesn't move or appears frozen

**Diagnose:**
```matlab
% Check trajectory generation
traj.trajFun(@(o) struct('nFr', 240, 'cic.screen.frameRate', 120))

% Check mapping
traj.mappingType
traj.mappingWeights

% Visualize
visualizeTraj3D(...)
```

**Solutions:**
- Verify velocity is non-zero: `traj.velocity = [20; 0; 0]`
- Check mappingWeights aren't all zeros: `[1, 0, 0]` not `[0, 0, 0]`
- Ensure trajectory generates multiple different positions

### Issue 2: Motion goes off-screen

**Diagnose:**
```matlab
% Check coordinate ranges
traj.coordRangeX
traj.coordRangeY

% Check mapping normalization
% If range is too small, motion gets compressed
```

**Solutions:**
- Increase coordRangeMargin: `traj.coordRangeMargin = 0.2` (20% margin)
- Manually set ranges to match screen: `traj.coordRangeX = [-800, 800]`
- Reduce velocity: `traj.velocity = [10; 0; 0]`
- Use screenScale: `traj.screenScale = 0.5` (half the motion)

### Issue 3: Motion is jerky or seems wrong

**Diagnose:**
```matlab
% Check frame rate matches
c.screen.frameRate

% Verify trajectory
visualizeTraj3D(...)
```

**Solutions:**
- Match frame rate: neurostim auto-detects, but verify in PTB window
- Check trajectory doesn't have discontinuities
- If Gabor: verify gaborSigma is reasonable for trial duration

### Issue 4: Stimulus appears in wrong location

**Diagnose:**
```matlab
% Check initial position
traj.initPos

% Check offset
traj.offset

% Check Y position
traj.Y  % Should always be 0
```

**Solutions:**
- Set initial position: `traj.initPos = 0`
- Use offset for systematic shift: `traj.offset = 50`
- Don't manually set Y: let afterFrame() handle it

## Performance Considerations

For smooth motion:

1. **Frame rate**: Target 120 Hz minimum (60 Hz if limited)
   ```matlab
   c.screen.frameRate  % Check actual rate
   ```

2. **Trajectory complexity**: Keep simple (linear, sinusoid)
   - Avoid heavy computation in trajectory function
   - Pre-calculate if possible

3. **Number of conditions**: Reasonable limits
   - Under 50 conditions: no issues
   - Over 100: consider performance

4. **Screen resolution**: Affects performance
   - HD (1920x1080): good
   - 4K (3840x2160): may need optimization

## Full Experiment Template

```matlab
function c = my_traj3d_experiment()
    import neurostim.*

    % Initialize
    c = cic.main();
    c.screen.type = 'PTB';
    c.screen.color.background = [0.5, 0.5, 0.5];
    c.trialDuration = 2000;
    c.nrTrials = 10;

    % Create stimulus
    traj = stimuli.traj3D(c, 'motion');
    traj.color = [1, 1, 1];
    traj.scale.x = 1;
    traj.scale.y = 1;
    traj.on = 0;
    traj.duration = 2000;

    % Configure trajectory
    traj.addProperty('startPos', [0; 0; 0]);
    traj.addProperty('velocity', [20; 0; 0]);
    traj.trajFun = @stimuli.traj3D.straightLine;

    % Configure mapping
    traj.mappingType = 'weightedSum';
    traj.mappingWeights = [1, 0, 0];
    traj.autoCoordRange = true;
    traj.coordRangeMargin = 0.1;

    % Optional: design with conditions
    % d = design('speed', [10, 20, 30]);
    % c.addDesign(d);
    % traj.velocity = @(cic) [cic.condition*10; 0; 0];

    % Run
    % c.run();
end
```

## Advanced: Custom Trajectory Functions

If you need complex motion not covered by straightLine or gaborModulated:

```matlab
% Define in your experiment file or separate .m file
function traj = myComplexMotion(o)
    t = (0:o.nFr-1) / o.cic.screen.frameRate;

    % Example: Figure-8 pattern
    traj(1, :) = 20 * sin(2*pi*t/2);      % X: slow sine
    traj(2, :) = 10 * sin(4*pi*t/2);      % Y: faster sine
    traj(3, :) = zeros(1, o.nFr);         % Z: constant
end

% Use it
traj.trajFun = @myComplexMotion;
```

## Monitoring and Logging

PTB integration automatically logs:
- Trial timing
- Stimulus onset/offset
- Eye position (if eyetracker connected)
- Response data (if behaviors defined)

Access trial data:
```matlab
c.data          % All experiment data
c.trial         % Current trial info
c.trial.data    % Data for current trial
```

## Next Steps

1. Run `traj3D_experiment()` to see it in action
2. Modify velocities and mapping weights
3. Create your own trajectory function for your experiment
4. Add behavioral responses if needed
5. Integrate with eye tracking (if available)

See also:
- `traj3D_README.md` - Mathematical definitions
- `traj3D_demo.m` - Configuration examples
- `visualizeTraj3D.m` - Trajectory verification
