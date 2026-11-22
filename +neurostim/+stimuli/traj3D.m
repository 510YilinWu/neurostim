classdef traj3D < neurostim.stimulus
    % Class for updating stimulus position on screen according to a time-parametrized
    % 3D trajectory function, mapped to horizontal motion via projection/mapping.
    %
    % The 3D trajectory is defined by a function handle that takes time as input
    % and returns a 3x1 vector [x(t); y(t); z(t)] in global coordinate space.
    %
    % The 3D position is then mapped to 1D horizontal screen motion using either:
    % 1. Weighted sum: screen_x = a*x(t) + b*y(t) + c*z(t)
    % 2. Magnitude: screen_x = sqrt(sum of selected components squared)
    %
    % Predefined static trajectory functions:
    % - traj3D.straightLine - constant velocity motion along direction vector
    % - traj3D.gaborModulated - Gaussian-modulated sinusoid in Y, linear in X, constant Z
    %
    % The stimulus remains a single dot that moves along the horizontal axis.
    % Use visualizeTrajectory() method to plot the 3D path and 2D projections.

    properties (Access=protected)
    end

    methods (Access = public)
        function o = traj3D(c, name)
            o = o@neurostim.stimulus(c, name);

            % Basic trajectory parameters
            o.addProperty('nFr', 0, 'validate', @isnumeric); % number of frames
            o.addProperty('trajFun', [], 'validate', @ishandle); % function handle for 3D trajectory
            o.addProperty('trajParams', {}, 'validate', @iscell); % parameters for trajectory function

            % 3D trajectory storage
            o.addProperty('traj3D', zeros(3, 0), 'validate', @isnumeric); % [3 x nFr] array of 3D positions

            % Mapping from 3D to 1D (screen horizontal)
            o.addProperty('mappingType', 'weightedSum', 'validate', @(x) ismember(x, {'weightedSum', 'magnitude'}));
            o.addProperty('mappingWeights', [1 0 0], 'validate', @isnumeric); % [a, b, c] for weighted sum
            o.addProperty('mappingComponents', [2 3], 'validate', @isnumeric); % components for magnitude (indices 1=x, 2=y, 3=z)

            % Global coordinate ranges (auto-calculated or manual)
            o.addProperty('coordRangeX', [-1 1], 'validate', @isnumeric); % [min max]
            o.addProperty('coordRangeY', [-1 1], 'validate', @isnumeric);
            o.addProperty('coordRangeZ', [-1 1], 'validate', @isnumeric);
            o.addProperty('autoCoordRange', true, 'validate', @islogical); % auto-calculate from trajectory
            o.addProperty('coordRangeMargin', 0.1, 'validate', @isnumeric); % margin for auto-range (fraction of range)

            % Visual parameters
            o.addProperty('initPos', [], 'validate', @isnumeric); % initial position (frame 0)
            o.addProperty('offset', 0, 'validate', @isnumeric); % horizontal offset
            o.addProperty('screenScale', 1, 'validate', @isnumeric); % scaling factor for screen coordinates

            % Optional noise
            o.addProperty('noiseFun', [], 'validate', @ishandle);
            o.addProperty('noiseParams', {}, 'validate', @iscell);
            o.addProperty('iNoise', 1, 'validate', @isnumeric);
            o.addProperty('nNoise', 0, 'validate', @isnumeric);
            o.addProperty('noiseTraj', zeros(0, 0, 0), 'validate', @isnumeric); % [nNoise x 1 x nFr]

            % Frame-by-frame screen position
            o.addProperty('screenTraj', [], 'validate', @isnumeric); % [1 x nFr] array of screen x positions

            o.on = 0;
            addRNGstream(o);
        end

        function beforeExperiment(o)
            % Calculate number of frames and auto-calculate coordinate ranges
            o.nFr = round((o.duration / 1000) * o.cic.screen.frameRate);

            % Generate the full 3D trajectory for one trial to determine ranges
            if isempty(o.trajParams)
                traj = o.trajFun(o);
            else
                traj = o.trajFun(o.trajParams{:});
            end

            % Auto-calculate coordinate ranges if requested
            if o.autoCoordRange
                margin_x = (max(traj(1, :)) - min(traj(1, :))) * o.coordRangeMargin;
                margin_y = (max(traj(2, :)) - min(traj(2, :))) * o.coordRangeMargin;
                margin_z = (max(traj(3, :)) - min(traj(3, :))) * o.coordRangeMargin;

                o.coordRangeX = [min(traj(1, :)) - margin_x, max(traj(1, :)) + margin_x];
                o.coordRangeY = [min(traj(2, :)) - margin_y, max(traj(2, :)) + margin_y];
                o.coordRangeZ = [min(traj(3, :)) - margin_z, max(traj(3, :)) + margin_z];
            end

            % Generate frozen noise if specified
            if o.nNoise > 0
                if isempty(o.noiseParams)
                    o.noiseTraj = o.noiseFun(o);
                else
                    o.noiseTraj = o.noiseFun(o.noiseParams{:});
                end
            end
        end

        function beforeTrial(o)
            % Generate 3D trajectory for this trial
            if isempty(o.trajParams)
                o.traj3D = o.trajFun(o);
            else
                o.traj3D = o.trajFun(o.trajParams{:});
            end

            % Map 3D trajectory to 1D screen position
            o.screenTraj = o.mapTo1D(o.traj3D);

            % Apply offset
            o.screenTraj = o.screenTraj + o.offset;

            % Add noise if specified
            if o.nNoise > 0
                noise = squeeze(o.noiseTraj(o.iNoise, 1, :))';
                o.screenTraj = o.screenTraj + noise;
            end

            % Set position for frame 0
            if isempty(o.initPos)
                o.X = o.screenTraj(1);
            else
                o.X = o.initPos;
            end
            o.Y = 0; % always on horizontal axis
        end

        function afterFrame(o)
            % Update position for the next frame
            if o.frame >= 1 && o.frame <= length(o.screenTraj)
                o.X = o.screenTraj(o.frame);
                o.Y = 0;
            end
        end

        function screenX = mapTo1D(o, traj3D)
            % Map 3D trajectory to 1D screen position
            % traj3D: [3 x nFr] array of 3D positions
            % screenX: [1 x nFr] array of screen x positions

            if strcmp(o.mappingType, 'weightedSum')
                % screen_x = a*x(t) + b*y(t) + c*z(t)
                weights = o.mappingWeights;
                if length(weights) < 3
                    weights = [weights, zeros(1, 3 - length(weights))];
                end
                screenX = weights(1) * traj3D(1, :) + weights(2) * traj3D(2, :) + weights(3) * traj3D(3, :);
            elseif strcmp(o.mappingType, 'magnitude')
                % screen_x = sqrt(sum of selected components squared)
                components = o.mappingComponents;
                screenX = zeros(1, size(traj3D, 2));
                for i = 1:length(components)
                    screenX = screenX + traj3D(components(i), :) .^ 2;
                end
                screenX = sqrt(screenX);
            else
                error('Unknown mapping type: %s', o.mappingType);
            end

            % Normalize to coordinate range and apply screen scale
            traj_range = max(screenX) - min(screenX);
            if traj_range > 0
                screenX = (screenX - min(screenX)) / traj_range * ...
                    (o.coordRangeX(2) - o.coordRangeX(1)) + o.coordRangeX(1);
            end
            screenX = screenX * o.screenScale;
        end

    end

    methods (Static)
        function traj = straightLine(varargin)
            % Generate a straight-line trajectory with constant velocity
            %
            % Usage:
            % traj = traj3D.straightLine(startPos, velocity, nFrames, frameRate)
            % OR for use with stimulus object:
            % traj = traj3D.straightLine(o) where o has properties:
            %   - startPos: [3x1] starting position
            %   - velocity: [3x1] velocity vector
            %   - nFr: number of frames
            %   - cic.screen.frameRate: frame rate

            if nargin == 1 && isobject(varargin{1})
                % Called with stimulus object
                o = varargin{1};
                startPos = o.startPos;
                velocity = o.velocity;
                nFr = o.nFr;
                frameRate = o.cic.screen.frameRate;
            else
                % Called with individual parameters
                startPos = varargin{1};
                velocity = varargin{2};
                nFr = varargin{3};
                frameRate = varargin{4};
            end

            % Ensure column vectors
            startPos = startPos(:);
            velocity = velocity(:);

            % Time vector
            t = (0:nFr-1) / frameRate;

            % Generate trajectory: position(t) = startPos + velocity * t
            traj = startPos + velocity * t;
        end

        function traj = gaborModulated(varargin)
            % Generate a trajectory with linear motion in X and Gaussian-modulated
            % sinusoid in Y, constant Z.
            %
            % x(t) = v * t
            % y(t) = A * exp(-(t - t0)^2 / (2*sigma^2)) * cos(2*pi*f*t + phi)
            % z(t) = z0
            %
            % Usage:
            % traj = traj3D.gaborModulated(xSpeed, yAmplitude, yFreq, ySigma, yPhase, z0, nFrames, frameRate)
            % OR for use with stimulus object:
            % traj = traj3D.gaborModulated(o) where o has properties:
            %   - xSpeed: velocity in x direction
            %   - gaborAmp: amplitude of y modulation (A)
            %   - gaborFreq: frequency of sinusoid (f)
            %   - gaborSigma: sigma of Gaussian envelope
            %   - gaborPhase: phase of sinusoid (phi)
            %   - gaborCenter: center time of Gaussian (t0) - if empty, uses middle of trial
            %   - zOffset: constant z position (z0)
            %   - nFr: number of frames
            %   - cic.screen.frameRate: frame rate

            if nargin == 1 && isobject(varargin{1})
                % Called with stimulus object
                o = varargin{1};
                xSpeed = o.xSpeed;
                yAmp = o.gaborAmp;
                yFreq = o.gaborFreq;
                ySigma = o.gaborSigma;
                yPhase = o.gaborPhase;
                z0 = o.zOffset;
                nFr = o.nFr;
                frameRate = o.cic.screen.frameRate;

                % If center time not specified, use middle of trial
                if isempty(o.gaborCenter)
                    t0 = (nFr - 1) / (2 * frameRate);
                else
                    t0 = o.gaborCenter;
                end
            else
                % Called with individual parameters
                xSpeed = varargin{1};
                yAmp = varargin{2};
                yFreq = varargin{3};
                ySigma = varargin{4};
                yPhase = varargin{5};
                z0 = varargin{6};
                nFr = varargin{7};
                frameRate = varargin{8};
                t0 = (nFr - 1) / (2 * frameRate); % default center
            end

            % Time vector
            t = (0:nFr-1) / frameRate;

            % X component: linear motion
            traj(1, :) = xSpeed * t;

            % Y component: Gaussian-modulated sinusoid
            gauss_envelope = exp(-(t - t0).^2 / (2 * ySigma^2));
            traj(2, :) = yAmp * gauss_envelope .* cos(2*pi*yFreq*t + yPhase);

            % Z component: constant
            traj(3, :) = z0 * ones(1, nFr);
        end
    end

end
