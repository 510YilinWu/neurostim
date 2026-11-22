# traj3D: 3D Trajectory Stimulus Plugin for Neurostim

## Overview

`traj3D` is a neurostim stimulus plugin that generates visually interpretable motion stimuli from parameterized 3D trajectory functions. The core concept is:

1. Define a 3D trajectory in global space: **x(t), y(t), z(t)**
2. Project/map the 3D position to 1D horizontal screen motion
3. Display as a single dot moving horizontally on the screen
4. Visualize the full 3D trajectory path for verification

This enables experiments where visual motion is derived from mathematically defined 3D paths with precise control.

## Installation

The plugin is located at:
- `/Users/ywuu0245/PHD-code/neurostim/+neurostim/+stimuli/traj3D.m`

Supporting utilities:
- `visualizeTraj3D.m` - Visualization function
- `traj3D_demo.m` - Usage examples
- `traj3D_README.md` - This file

## Quick Start

### Basic Usage

```matlab
% 1. Create stimulus in your experiment class
traj = neurostim.stimuli.traj3D(c, 'trajectory');

% 2. Set duration and frame rate (inherited from neurostim.stimulus)
traj.duration = 2000;  % milliseconds

% 3. Configure trajectory function (choose one of the built-in or custom)
traj.trajFun = @neurostim.stimuli.traj3D.gaborModulated;

% 4. Add required trajectory parameters as properties
traj.addProperty('xSpeed', 10);
traj.addProperty('gaborAmp', 5);
traj.addProperty('gaborFreq', 2);
traj.addProperty('gaborSigma', 0.3);
traj.addProperty('gaborPhase', 0);
traj.addProperty('zOffset', 0);

% 5. Configure mapping from 3D to screen
traj.mappingType = 'weightedSum';      % 'weightedSum' or 'magnitude'
traj.mappingWeights = [1, 0, 0];       % For weighted sum: a*x + b*y + c*z
% OR
traj.mappingType = 'magnitude';        % sqrt(y^2 + z^2)
traj.mappingComponents = [2, 3];

% 6. Set coordinate ranges (auto or manual)
traj.autoCoordRange = true;            % Auto-calculate from trajectory
traj.coordRangeMargin = 0.1;           % 10% margin

% 7. Done! The stimulus will automatically:
%    - Generate the 3D trajectory in beforeTrial
%    - Map to screen position
%    - Update position each frame in afterFrame
```

## Core Concepts

### 1. 3D Trajectories

A 3D trajectory is defined as three time-parametrized functions:
```
x(t) = ...
y(t) = ...
z(t) = ...
```

All trajectories must accept time as the independent variable and return values for all three dimensions.

### 2. 3D-to-1D Projection/Mapping

The 3D position is projected to a single 1D horizontal screen position using one of two methods:

#### Weighted Sum
```
screen_x = a·x(t) + b·y(t) + c·z(t)
```
Configure with:
```matlab
traj.mappingType = 'weightedSum';
traj.mappingWeights = [a, b, c];  % e.g., [1, 0, 0] uses only x
```

#### Magnitude (Euclidean norm of selected components)
```
screen_x = √(y(t)² + z(t)²)
```
Configure with:
```matlab
traj.mappingType = 'magnitude';
traj.mappingComponents = [2, 3];  % indices: 1=x, 2=y, 3=z
```

### 3. Coordinate Ranges

The plugin manages coordinate ranges in two ways:

**Auto-calculation (recommended):**
```matlab
traj.autoCoordRange = true;       % Enabled by default
traj.coordRangeMargin = 0.1;      % Add 10% margin around trajectory
```
The plugin automatically:
1. Generates a trajectory to determine bounds
2. Expands bounds by the margin percentage
3. Uses these ranges to normalize screen positions

**Manual specification:**
```matlab
traj.autoCoordRange = false;
traj.coordRangeX = [-50, 50];     % in global space units
traj.coordRangeY = [-30, 30];
traj.coordRangeZ = [-20, 20];
```

### 4. Frame-Based Animation

The plugin follows neurostim's frame-based architecture:
- **Frame 0**: Initial position (set by `initPos` or matches frame 1)
- **Frame 1 onwards**: Position from trajectory at corresponding time

```
frame 0: t = 0 ms
frame 1: t = 1/frameRate seconds
frame 2: t = 2/frameRate seconds
...
```

## Built-in Trajectory Functions

### 1. Straight Line Motion

**Mathematical form:**
```
position(t) = startPos + velocity · t
```

**Usage:**
```matlab
traj.addProperty('startPos', [0; 0; 0]);
traj.addProperty('velocity', [10; 5; 0]);  % [vx, vy, vz]
traj.trajFun = @neurostim.stimuli.traj3D.straightLine;
```

**Example 1: Pure horizontal motion**
```matlab
traj.velocity = [10; 0; 0];
traj.mappingWeights = [1, 0, 0];  % use x-component
```

**Example 2: Diagonal motion (x and y)**
```matlab
traj.velocity = [10; 5; 0];
traj.mappingWeights = [0.67, 0.33, 0];  % weighted average
```

**Example 3: Vertical depth motion**
```matlab
traj.velocity = [0; 0; 10];
traj.mappingType = 'magnitude';
traj.mappingComponents = [3];  % use z-component
```

### 2. Gabor-Modulated Motion

**Mathematical form:**
```
x(t) = v_x · t
y(t) = A · exp(-(t-t₀)²/(2σ²)) · cos(2πft + φ)
z(t) = z₀
```

This creates motion along X with a Gaussian-enveloped sinusoid modulation in Y.

**Usage:**
```matlab
traj.addProperty('xSpeed', 10);           % velocity in x (units/sec)
traj.addProperty('gaborAmp', 5);          % amplitude of y modulation (A)
traj.addProperty('gaborFreq', 2);         % frequency of sinusoid (f, Hz)
traj.addProperty('gaborSigma', 0.3);      % sigma of Gaussian envelope (seconds)
traj.addProperty('gaborPhase', 0);        % phase offset of sinusoid (radians)
traj.addProperty('gaborCenter', []);      % center time (empty = middle of trial)
traj.addProperty('zOffset', 0);           % constant z position
traj.trajFun = @neurostim.stimuli.traj3D.gaborModulated;
```

**Example 1: Low-frequency modulation**
```matlab
traj.xSpeed = 10;
traj.gaborAmp = 3;
traj.gaborFreq = 0.5;      % Half oscillation per second
traj.gaborSigma = 0.5;     % Sigma = half the trial duration (wider envelope)
traj.mappingType = 'magnitude';
traj.mappingComponents = [2, 3];  % Include y-modulation in mapping
```

**Example 2: High-frequency modulation, narrow envelope**
```matlab
traj.xSpeed = 10;
traj.gaborAmp = 5;
traj.gaborFreq = 5;        % 5 Hz oscillation
traj.gaborSigma = 0.1;     % Narrow Gaussian envelope
traj.mappingWeights = [0.8, 0.2, 0];  % Mostly x, some y
```

### 3. Custom Trajectory Functions

Create your own trajectory function following this pattern:

```matlab
function traj = myCustomTrajectory(varargin)
    % Parse inputs - must support both calling conventions
    if nargin == 1 && isobject(varargin{1})
        % Called with stimulus object
        o = varargin{1};
        nFr = o.nFr;
        frameRate = o.cic.screen.frameRate;
        % Get other parameters from o
        param1 = o.myParam1;
    else
        % Called with individual parameters
        nFr = varargin{1};
        frameRate = varargin{2};
        param1 = varargin{3};
    end

    % Create time vector
    t = (0:nFr-1) / frameRate;

    % Define 3D trajectory (always [3 x nFr])
    traj(1, :) = 10 * t;              % x component
    traj(2, :) = 3 * sin(2*pi*t);     % y component
    traj(3, :) = 2 * cos(4*pi*t);     % z component
end
```

Register it with the stimulus:
```matlab
traj.trajFun = @myCustomTrajectory;
traj.addProperty('myParam1', 0);  % Add as property if needed
```

## Visualization

### Verify Your Trajectory

Before running experiments, visualize the 3D trajectory and its mapping:

```matlab
% Visualize the trajectory
figs = neurostim.stimuli.visualizeTraj3D(...
    @neurostim.stimuli.traj3D.gaborModulated, ...
    {}, ...                    % trajParams (empty if using stimulus properties)
    240, ...                   % nFr
    120, ...                   % frameRate
    'magnitude', ...           % mappingType
    [], ...                    % mappingWeights (unused for magnitude)
    struct(...                 % coordRanges
        'coordRangeX', [-15, 15], ...
        'coordRangeY', [-10, 10], ...
        'coordRangeZ', [-5, 5] ...
    ) ...
);

% Returns structure with figure handles:
% figs.fig3D    - 3D trajectory plot
% figs.figXY    - XY projection
% figs.figXZ    - XZ projection
% figs.figYZ    - YZ projection
% figs.figScreen - Screen x position vs time
```

This generates 5 figures:
1. **3D Trajectory**: Full 3D path with start (green) and end (red) markers
2. **XY Projection**: Top-down view
3. **XZ Projection**: Front view
4. **YZ Projection**: Side view
5. **Screen Position**: The mapped 1D motion over time

Use these to verify that:
- The 3D path matches your intended trajectory
- The mapping correctly projects to 1D motion
- The stimulus will behave as expected on screen

## Advanced Configuration

### Coordinate Range Management

**Understanding the normalization:**
1. Screen position is calculated from 3D trajectory using the mapping function
2. Raw screen values are then normalized to the coordinate range
3. Coordinate range defines the bounds in the stimulus's local coordinate system

Example with weighted sum mapping:
```matlab
traj.mappingWeights = [1, 0, 0];      % screen_x = x(t)
traj.coordRangeX = [-20, 20];         % x ranges from -20 to 20 units
traj.autoCoordRange = false;

% If x(t) ranges from 0 to 10 units in the trajectory:
% 0 -> maps to -20 (normalized to left side of range)
% 10 -> maps to 20 (normalized to right side of range)
```

### Screen Scaling

Apply post-projection scaling:
```matlab
traj.screenScale = 1.5;  % Amplify screen motion by 1.5x
```

### Initial Position

Control the position at frame 0 (before motion starts):
```matlab
traj.initPos = 5;         % Start at x=5 on screen
% If empty, uses frame 1 position
```

### Horizontal Offset

Shift the entire trajectory horizontally:
```matlab
traj.offset = 10;  % Shift all positions right by 10 units
```

### Additive Noise

(Optional) Add frozen noise to the trajectory like `targXY`:
```matlab
traj.noiseFun = @myNoiseFunction;
traj.nNoise = 10;         % 10 independent noise instances
traj.iNoise = 1;          % Use first instance (set in factorial design)
```

## Parameter Reference

### Core Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| **trajFun** | function handle | [] | Trajectory function |
| **trajParams** | cell | {} | Parameters passed to trajFun |
| **nFr** | int | 0 | Number of frames (auto-set from duration) |

### Mapping Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| **mappingType** | string | 'weightedSum' | 'weightedSum' or 'magnitude' |
| **mappingWeights** | [a,b,c] | [1,0,0] | Weights for weighted sum |
| **mappingComponents** | indices | [2,3] | Components for magnitude |

### Coordinate Range Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| **autoCoordRange** | bool | true | Auto-calculate ranges |
| **coordRangeX** | [min,max] | [-1,1] | Global x range |
| **coordRangeY** | [min,max] | [-1,1] | Global y range |
| **coordRangeZ** | [min,max] | [-1,1] | Global z range |
| **coordRangeMargin** | double | 0.1 | Margin for auto-calc (fraction) |

### Display Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| **screenScale** | double | 1 | Post-projection scaling |
| **initPos** | scalar | [] | Initial position at frame 0 |
| **offset** | scalar | 0 | Horizontal offset |

### Noise Properties (Optional)

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| **noiseFun** | function handle | [] | Noise function |
| **noiseParams** | cell | {} | Noise parameters |
| **nNoise** | int | 0 | Number of noise instances |
| **iNoise** | int | 1 | Current noise index |

### Storage Properties

| Property | Type | Purpose |
|----------|------|---------|
| **traj3D** | [3×nFr] | Full 3D trajectory |
| **screenTraj** | [1×nFr] | Mapped 1D screen positions |
| **noiseTraj** | [nNoise×1×nFr] | Noise instances |

## Common Patterns

### Pattern 1: X-dominated motion with subtle Y modulation
```matlab
traj.velocity = [10; 2; 0];  % Mostly x, some y
traj.mappingWeights = [0.8, 0.2, 0];
traj.mappingType = 'weightedSum';
```

### Pattern 2: Depth (Z) modulation
```matlab
traj.addProperty('zSpeed', 5);
traj.velocity = [0; 0; zSpeed];
traj.mappingType = 'magnitude';
traj.mappingComponents = [3];  % Use only z
```

### Pattern 3: Complex 3D spiral
Create custom function:
```matlab
function traj = spiralTrajectory(radius, pitch, nFr, frameRate)
    t = (0:nFr-1) / frameRate;
    theta = 2*pi*t / (nFr/frameRate);  % Complete rotation over trial
    traj(1, :) = radius * cos(theta);
    traj(2, :) = radius * sin(theta);
    traj(3, :) = pitch * t;
end
```

### Pattern 4: Stop-and-go motion
```matlab
function traj = stopAndGoTrajectory(speed, nFr, frameRate)
    t = (0:nFr-1) / frameRate;
    phase = mod(t, 0.5);  % 0.5 second cycles
    traj(1, :) = speed * t .* (phase < 0.25);  % Move for 250ms, stop for 250ms
    traj(2, :) = 0;
    traj(3, :) = 0;
end
```

## Troubleshooting

### Issue: Stimulus not moving
- Check that `trajFun` is set to a valid function handle
- Verify `duration` is > 0
- Check that `nFr` is auto-calculated correctly in `beforeExperiment`

### Issue: Mapping looks wrong
- Use `visualizeTraj3D` to check projections
- Verify `mappingType` and `mappingWeights`/`mappingComponents` match intended projection
- Check `coordRangeX/Y/Z` values

### Issue: Screen position out of bounds
- May be normal if trajectory extends beyond expected range
- Adjust `coordRangeX/Y/Z` or enable `autoCoordRange`
- Use `screenScale` to adjust amplitude

### Issue: Stimulus appears frozen
- Check that trajectory is not constant (e.g., `velocity = [0,0,0]`)
- Verify `mappingType` isn't projecting changing dimensions to zero

## See Also

- `targXY.m` - 2D trajectory stimulus (reference implementation)
- `neurostim.stimulus` - Base stimulus class
- `traj3D_demo.m` - Usage examples
- `visualizeTraj3D.m` - Visualization utility

## Author Notes

Based on `targXY.m` but extended to:
- Full 3D trajectory definition
- Flexible 3D-to-1D projection via weighted sum or magnitude
- Automatic coordinate range calculation
- Built-in visualization for trajectory verification

The design emphasizes mathematical precision and visual interpretability for neuroscience experiments.
