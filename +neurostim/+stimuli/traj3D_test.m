%% traj3D Test Script
% Basic tests to verify the traj3D stimulus plugin functionality

function passed = traj3D_test()
    disp('=== traj3D Plugin Tests ===');
    passed = 0;
    total = 0;

    % Test 1: Create stimulus class
    total = total + 1;
    try
        % Create a mock container with minimal required structure
        c = struct();
        c.screen = struct();
        c.screen.frameRate = 120;

        % Create stimulus
        stim = neurostim.stimuli.traj3D(c, 'test_traj');
        disp('✓ Test 1: Stimulus creation successful');
        passed = passed + 1;
    catch ME
        disp(['✗ Test 1 FAILED: ' ME.message]);
    end

    % Test 2: Straight line trajectory generation
    total = total + 1;
    try
        nFr = 240;
        frameRate = 120;
        startPos = [0; 0; 0];
        velocity = [10; 5; 0];

        % Create a temporary object for testing
        testObj = struct();
        testObj.startPos = startPos;
        testObj.velocity = velocity;
        testObj.nFr = nFr;
        testObj.cic = struct();
        testObj.cic.screen.frameRate = frameRate;

        % Call straight line with parameters
        traj = neurostim.stimuli.traj3D.straightLine(startPos, velocity, nFr, frameRate);

        % Verify dimensions
        assert(size(traj, 1) == 3, 'Trajectory should have 3 rows');
        assert(size(traj, 2) == nFr, 'Trajectory should have nFr columns');

        % Verify values
        t = (0:nFr-1) / frameRate;
        expected_x = 10 * t;
        expected_y = 5 * t;

        assert(max(abs(traj(1, :) - expected_x)) < 1e-10, 'X trajectory mismatch');
        assert(max(abs(traj(2, :) - expected_y)) < 1e-10, 'Y trajectory mismatch');

        disp('✓ Test 2: Straight line trajectory correct');
        passed = passed + 1;
    catch ME
        disp(['✗ Test 2 FAILED: ' ME.message]);
    end

    % Test 3: Gabor-modulated trajectory generation
    total = total + 1;
    try
        xSpeed = 10;
        yAmp = 5;
        yFreq = 2;
        ySigma = 0.3;
        yPhase = 0;
        z0 = 0;
        nFr = 240;
        frameRate = 120;

        traj = neurostim.stimuli.traj3D.gaborModulated(xSpeed, yAmp, yFreq, ySigma, yPhase, z0, nFr, frameRate);

        % Verify dimensions
        assert(size(traj, 1) == 3, 'Trajectory should have 3 rows');
        assert(size(traj, 2) == nFr, 'Trajectory should have nFr columns');

        % Verify X is linear
        t = (0:nFr-1) / frameRate;
        expected_x = xSpeed * t;
        assert(max(abs(traj(1, :) - expected_x)) < 1e-10, 'X trajectory should be linear');

        % Verify Z is constant
        assert(max(abs(traj(3, :) - z0)) < 1e-10, 'Z should be constant');

        % Y should vary (not constant and not all zeros)
        assert(max(abs(traj(2, :))) > 0, 'Y should have non-zero values');

        disp('✓ Test 3: Gabor-modulated trajectory correct');
        passed = passed + 1;
    catch ME
        disp(['✗ Test 3 FAILED: ' ME.message]);
    end

    % Test 4: Weighted sum mapping
    total = total + 1;
    try
        % Simple 3D trajectory
        traj_test = [
            [1, 2, 3, 4, 5];  % x
            [0.5, 1, 1.5, 2, 2.5];  % y
            [0, 0, 0, 0, 0]  % z
        ];

        % Create minimal stimulus for mapping test
        c = struct();
        c.screen.frameRate = 120;
        stim = neurostim.stimuli.traj3D(c, 'test');
        stim.mappingType = 'weightedSum';
        stim.mappingWeights = [1, 0, 0];
        stim.coordRangeX = [0, 5];
        stim.autoCoordRange = false;

        % Test weighted sum: [1, 0, 0] should give x component only
        screenX = stim.mapTo1D(traj_test);
        assert(size(screenX, 1) == 1, 'Screen position should be 1D');
        assert(size(screenX, 2) == 5, 'Should have same number of frames');

        % With weights [1,0,0] and range [0,5], should match x exactly
        expected = [1, 2, 3, 4, 5];
        assert(max(abs(screenX - expected)) < 0.1, 'Weighted sum mapping incorrect');

        disp('✓ Test 4: Weighted sum mapping correct');
        passed = passed + 1;
    catch ME
        disp(['✗ Test 4 FAILED: ' ME.message]);
    end

    % Test 5: Magnitude mapping
    total = total + 1;
    try
        c = struct();
        c.screen.frameRate = 120;
        stim = neurostim.stimuli.traj3D(c, 'test');
        stim.mappingType = 'magnitude';
        stim.mappingComponents = [2, 3];
        stim.coordRangeX = [0, 10];
        stim.autoCoordRange = false;

        % Test with simple trajectory
        traj_test = [
            [0, 0, 0];      % x (not used)
            [3, 4, 0];      % y
            [4, 3, 0]       % z
        ];

        screenX = stim.mapTo1D(traj_test);

        % Expected magnitudes: sqrt(3^2 + 4^2) = 5, sqrt(4^2 + 3^2) = 5, sqrt(0) = 0
        expected_mag = [5, 5, 0];
        assert(max(abs(screenX - expected_mag)) < 0.1, 'Magnitude mapping incorrect');

        disp('✓ Test 5: Magnitude mapping correct');
        passed = passed + 1;
    catch ME
        disp(['✗ Test 5 FAILED: ' ME.message]);
    end

    % Summary
    disp(' ');
    disp(['=== Test Summary: ' num2str(passed) '/' num2str(total) ' passed ===']);

    if passed == total
        disp('✓ All tests passed!');
    else
        disp(['✗ ' num2str(total - passed) ' test(s) failed']);
    end

end

% Run tests if executed directly
if isempty(which('traj3D'))
    warning('traj3D stimulus class not found. Make sure neurostim is on path.');
else
    traj3D_test();
end
