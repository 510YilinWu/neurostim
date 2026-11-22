function figs = visualizeTraj3D(trajFunc, trajParams, nFr, frameRate, mappingType, mappingWeights, coordRanges)
    % Visualize a 3D trajectory with 3D plot and 2D projections
    %
    % Usage:
    % figs = visualizeTraj3D(trajFunc, trajParams, nFr, frameRate, mappingType, mappingWeights, coordRanges)
    %
    % Inputs:
    %   trajFunc - function handle for trajectory
    %   trajParams - cell array of parameters to pass to trajFunc
    %   nFr - number of frames
    %   frameRate - frame rate in Hz
    %   mappingType - 'weightedSum' or 'magnitude'
    %   mappingWeights - [a, b, c] for weighted sum mapping
    %   coordRanges - struct with fields coordRangeX, coordRangeY, coordRangeZ
    %                 (optional, will be auto-calculated if not provided)
    %
    % Outputs:
    %   figs - structure containing figure handles
    %       .fig3D - 3D trajectory plot
    %       .figXY - XY projection
    %       .figXZ - XZ projection
    %       .figYZ - YZ projection
    %       .figScreen - Screen x vs time

    % Generate trajectory
    if isempty(trajParams)
        traj = trajFunc();
    else
        traj = trajFunc(trajParams{:});
    end

    % Auto-calculate coordinate ranges if not provided
    if nargin < 7 || isempty(coordRanges)
        margin = 0.1;
        margin_x = (max(traj(1, :)) - min(traj(1, :))) * margin;
        margin_y = (max(traj(2, :)) - min(traj(2, :))) * margin;
        margin_z = (max(traj(3, :)) - min(traj(3, :))) * margin;

        coordRanges.coordRangeX = [min(traj(1, :)) - margin_x, max(traj(1, :)) + margin_x];
        coordRanges.coordRangeY = [min(traj(2, :)) - margin_y, max(traj(2, :)) + margin_y];
        coordRanges.coordRangeZ = [min(traj(3, :)) - margin_z, max(traj(3, :)) + margin_z];
    end

    % Map 3D to 1D screen position
    if strcmp(mappingType, 'weightedSum')
        weights = mappingWeights;
        if length(weights) < 3
            weights = [weights, zeros(1, 3 - length(weights))];
        end
        screenX = weights(1) * traj(1, :) + weights(2) * traj(2, :) + weights(3) * traj(3, :);
    elseif strcmp(mappingType, 'magnitude')
        screenX = sqrt(traj(2, :).^2 + traj(3, :).^2);
    end

    % Normalize screen position
    traj_range = max(screenX) - min(screenX);
    if traj_range > 0
        screenX = (screenX - min(screenX)) / traj_range * ...
            (coordRanges.coordRangeX(2) - coordRanges.coordRangeX(1)) + coordRanges.coordRangeX(1);
    end

    % Time vector
    t = (0:nFr-1) / frameRate;

    % Create figures
    figs = struct();

    % 3D trajectory
    figs.fig3D = figure('Name', '3D Trajectory', 'NumberTitle', 'off');
    plot3(traj(1, :), traj(2, :), traj(3, :), 'b-', 'LineWidth', 2);
    hold on;
    plot3(traj(1, 1), traj(2, 1), traj(3, 1), 'go', 'MarkerSize', 10, 'MarkerFaceColor', 'g'); % start
    plot3(traj(1, end), traj(2, end), traj(3, end), 'ro', 'MarkerSize', 10, 'MarkerFaceColor', 'r'); % end
    xlabel('X');
    ylabel('Y');
    zlabel('Z');
    title('3D Trajectory');
    grid on;
    legend('Trajectory', 'Start', 'End');
    set(gca, 'XLim', coordRanges.coordRangeX, 'YLim', coordRanges.coordRangeY, 'ZLim', coordRanges.coordRangeZ);

    % XY projection
    figs.figXY = figure('Name', 'XY Projection', 'NumberTitle', 'off');
    plot(traj(1, :), traj(2, :), 'b-', 'LineWidth', 2);
    hold on;
    plot(traj(1, 1), traj(2, 1), 'go', 'MarkerSize', 10, 'MarkerFaceColor', 'g');
    plot(traj(1, end), traj(2, end), 'ro', 'MarkerSize', 10, 'MarkerFaceColor', 'r');
    xlabel('X');
    ylabel('Y');
    title('XY Projection');
    grid on;
    legend('Trajectory', 'Start', 'End');
    set(gca, 'XLim', coordRanges.coordRangeX, 'YLim', coordRanges.coordRangeY);

    % XZ projection
    figs.figXZ = figure('Name', 'XZ Projection', 'NumberTitle', 'off');
    plot(traj(1, :), traj(3, :), 'b-', 'LineWidth', 2);
    hold on;
    plot(traj(1, 1), traj(3, 1), 'go', 'MarkerSize', 10, 'MarkerFaceColor', 'g');
    plot(traj(1, end), traj(3, end), 'ro', 'MarkerSize', 10, 'MarkerFaceColor', 'r');
    xlabel('X');
    ylabel('Z');
    title('XZ Projection');
    grid on;
    legend('Trajectory', 'Start', 'End');
    set(gca, 'XLim', coordRanges.coordRangeX, 'ZLim', coordRanges.coordRangeZ);

    % YZ projection
    figs.figYZ = figure('Name', 'YZ Projection', 'NumberTitle', 'off');
    plot(traj(2, :), traj(3, :), 'b-', 'LineWidth', 2);
    hold on;
    plot(traj(2, 1), traj(3, 1), 'go', 'MarkerSize', 10, 'MarkerFaceColor', 'g');
    plot(traj(2, end), traj(3, end), 'ro', 'MarkerSize', 10, 'MarkerFaceColor', 'r');
    xlabel('Y');
    ylabel('Z');
    title('YZ Projection');
    grid on;
    legend('Trajectory', 'Start', 'End');
    set(gca, 'YLim', coordRanges.coordRangeY, 'ZLim', coordRanges.coordRangeZ);

    % Screen position vs time
    figs.figScreen = figure('Name', 'Screen X Position vs Time', 'NumberTitle', 'off');
    plot(t, screenX, 'b-', 'LineWidth', 2);
    xlabel('Time (s)');
    ylabel('Screen X Position');
    title(sprintf('Mapped 1D Motion (%s)', mappingType));
    grid on;

end
