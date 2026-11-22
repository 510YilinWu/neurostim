%% traj3D Demo - Usage examples for 3D trajectory stimulus plugin
%
% This demo shows how to configure and use the traj3D stimulus plugin
% with the two built-in trajectory functions: straightLine and gaborModulated

%% Example 1: Straight Line Motion
% Linear motion along a direction vector in 3D space

disp('=== Example 1: Straight Line Trajectory ===');

% Create stimulus object (normally done in your experiment class)
% c is your neurostim container object
% traj_stim = neurostim.stimuli.traj3D(c, 'myTraj3D');

% Configuration for straight line motion
% xSpeed = 10;     % units/sec in x direction
% ySpeed = 0;      % units/sec in y direction
% zSpeed = 0;      % units/sec in z direction
% traj_stim.addProperty('startPos', [0; 0; 0]);
% traj_stim.addProperty('velocity', [xSpeed; ySpeed; zSpeed]);
% traj_stim.trajFun = @neurostim.stimuli.traj3D.straightLine;
% traj_stim.duration = 2000; % 2 seconds
%
% % Configure mapping from 3D to 1D screen position
% traj_stim.mappingType = 'weightedSum';
% traj_stim.mappingWeights = [1, 0, 0]; % Use only x component
%
% % Auto-calculate coordinate ranges from trajectory
% traj_stim.autoCoordRange = true;
% traj_stim.coordRangeMargin = 0.1; % 10% margin

%% Example 1 Alternative: Diagonal motion (equal motion in X and Y)
% Config for diagonal motion
% traj_stim.velocity = [10; 5; 0];
% traj_stim.mappingWeights = [0.7, 0.3, 0]; % weighted average of x and y
% traj_stim.mappingType = 'weightedSum';

%% Example 2: Gabor-Modulated Trajectory
% Linear motion in X with Gaussian-modulated sinusoidal motion in Y
% z(t) = constant
%
% x(t) = v_x * t
% y(t) = A * exp(-(t-t0)^2 / (2*sigma^2)) * cos(2*pi*f*t + phi)
% z(t) = z_0

disp('=== Example 2: Gabor-Modulated Trajectory ===');

% Configuration for Gabor-modulated motion
% traj_stim.addProperty('xSpeed', 10);          % velocity in x (units/sec)
% traj_stim.addProperty('gaborAmp', 5);         % amplitude of y oscillation (A)
% traj_stim.addProperty('gaborFreq', 2);        % frequency of sinusoid (f, in Hz)
% traj_stim.addProperty('gaborSigma', 0.3);     % sigma of Gaussian envelope (seconds)
% traj_stim.addProperty('gaborPhase', 0);       % phase offset of sinusoid (radians)
% traj_stim.addProperty('gaborCenter', []);     % center time of Gaussian (empty = middle of trial)
% traj_stim.addProperty('zOffset', 0);          % constant z position
% traj_stim.trajFun = @neurostim.stimuli.traj3D.gaborModulated;
% traj_stim.duration = 2000; % 2 seconds
%
% % Map to screen using magnitude of Y and Z components
% traj_stim.mappingType = 'magnitude';
% traj_stim.mappingComponents = [2, 3]; % use y and z
%
% % Auto-calculate ranges
% traj_stim.autoCoordRange = true;

%% Example 3: Custom Trajectory Function
% Create your own trajectory function

% Define a custom function in your code:
% function traj = myCustomTrajectory(varargin)
%     % Parse inputs
%     if nargin == 1 && isobject(varargin{1})
%         o = varargin{1};
%         nFr = o.nFr;
%         frameRate = o.cic.screen.frameRate;
%         % Get any other parameters from o
%         param1 = o.customParam1;
%     else
%         nFr = varargin{1};
%         frameRate = varargin{2};
%         param1 = varargin{3};
%     end
%
%     t = (0:nFr-1) / frameRate;
%
%     % Define your 3D trajectory
%     traj(1,:) = 10 * t;           % linear in x
%     traj(2,:) = 3 * sin(2*pi*t);  % sinusoid in y
%     traj(3,:) = 2 * cos(4*pi*t);  % different sinusoid in z
% end
%
% % Use it in stimulus:
% traj_stim.trajFun = @myCustomTrajectory;
% traj_stim.trajParams = {}; % or pass parameters as needed

%% Example 4: Manual Coordinate Ranges
% Instead of auto-calculating, manually set coordinate ranges

% traj_stim.autoCoordRange = false;
% traj_stim.coordRangeX = [-50, 50];   % in units
% traj_stim.coordRangeY = [-30, 30];
% traj_stim.coordRangeZ = [-20, 20];

%% Example 5: Using Magnitude Mapping with Specific Components
% Map only Y and Z components, ignoring X

% traj_stim.mappingType = 'magnitude';
% traj_stim.mappingComponents = [2, 3]; % indices: 1=x, 2=y, 3=z

%% Visualization
% After configuring, visualize the trajectory to verify correct mapping

disp('=== Visualizing a Straight Line Trajectory ===');

% Setup parameters for visualization
nFr = 240;           % 2 seconds at 120 Hz
frameRate = 120;

% Straight line trajectory parameters
xSpeed = 10;
ySpeed = 0;
zSpeed = 0;
startPos = [0; 0; 0];
velocity = [xSpeed; ySpeed; zSpeed];

% Create a simple trajectory function for visualization
trajFunc = @(nFr, frameRate, sp, vel) deal(nFr, frameRate, sp, vel) && ...
    (repmat(sp, 1, nFr) + vel * (0:nFr-1)/frameRate);

% Alternative: use the built-in function directly by creating a dummy object
% For now, manually create trajectory
t = (0:nFr-1) / frameRate;
traj_manual = [
    xSpeed * t;
    ySpeed * t;
    zSpeed * t
];

% Visualize with auto-calculated ranges
try
    figs = neurostim.stimuli.visualizeTraj3D( ...
        @(nFr, frameRate, sp, vel) sp + vel * (0:nFr-1)/frameRate, ...
        {nFr, frameRate, startPos, velocity}, ...
        nFr, frameRate, ...
        'weightedSum', [1, 0, 0], ...
        struct('coordRangeX', [-2, 22], 'coordRangeY', [-5, 5], 'coordRangeZ', [-5, 5]) ...
    );
    disp('Trajectory visualization completed');
catch ME
    disp('Note: Visualization function requires proper trajectory function setup');
    disp(ME.message);
end

%% Key Configuration Parameters Summary

% ===== Trajectory Parameters =====
% trajFun           - Function handle for 3D trajectory
% trajParams        - Cell array of parameters to pass to trajFun
% nFr               - Number of frames (auto-calculated from duration)
%
% ===== Mapping Parameters (3D to 1D) =====
% mappingType       - 'weightedSum' or 'magnitude'
% mappingWeights    - [a, b, c] for weighted sum: screen_x = a*x + b*y + c*z
% mappingComponents - [indices] for magnitude: screen_x = sqrt(sum of components)
%
% ===== Coordinate Range Parameters =====
% autoCoordRange    - Boolean: auto-calculate ranges from trajectory
% coordRangeX       - [min, max] for x in global space
% coordRangeY       - [min, max] for y in global space
% coordRangeZ       - [min, max] for z in global space
% coordRangeMargin  - Margin for auto-range as fraction of range
%
% ===== Display Parameters =====
% initPos           - Initial position at frame 0 (empty = use frame 1)
% offset            - Horizontal offset for screen position
% screenScale       - Scaling factor for screen coordinates
%
% ===== Optional Noise =====
% noiseFun          - Function handle for noise
% noiseParams       - Parameters for noise function
% iNoise            - Index of current noise instance
% nNoise            - Total number of noise instances

%% Notes
% - All trajectories are time-parametrized: x(t), y(t), z(t)
% - Screen display is always horizontal (Y fixed at 0)
% - Frame 0 is the initial position; frame 1 starts the motion
% - Use visualizeTraj3D to debug mapping and verify trajectories

disp('traj3D demo complete');
