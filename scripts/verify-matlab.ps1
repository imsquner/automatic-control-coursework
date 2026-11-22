$matlabCommand = Get-Command matlab -ErrorAction Stop
$matlabCode = @'
fprintf('MATLAB_VERSION=%s RELEASE=%s\n', version, version('-release'));
assert(~isempty(ver('control')), 'Control System Toolbox not installed');
assert(~isempty(ver('simulink')), 'Simulink not installed');

coolingRate = 0.1;
initialDelta = 40;
stopTime = 10;
acceptanceTolerance = 1e-5;
expected = initialDelta * exp(-coolingRate * stopTime);

plant = ss(-coolingRate, 1, 1, 0);
assert(abs(dcgain(plant) - 1 / coolingRate) < 1e-9);
fprintf('CONTROL_TOOLBOX=PASS\n');

options = odeset('RelTol', 1e-9, 'AbsTol', 1e-10);
[time, delta] = ode45(@(~, delta) -coolingRate * delta, [0 stopTime], initialDelta, options);
matlabError = abs(delta(end) - expected);
assert(matlabError < acceptanceTolerance, 'MATLAB result outside tolerance');
figureHandle = figure('Visible', 'off');
axesHandle = axes('Parent', figureHandle);
lineHandle = plot(axesHandle, time, delta);
drawnow;
assert(numel(lineHandle.YData) == numel(time), 'Plot sample count mismatch');
close(figureHandle);
fprintf('MATLAB_ODE_AND_PLOT=PASS actual=%.8f expected=%.8f error=%.3g\n', delta(end), expected, matlabError);

modelName = 'codex_temperature_decay_smoke';
load_system('simulink');
new_system(modelName);
add_block('simulink/Continuous/Integrator', [modelName '/Temperature'], 'InitialCondition', num2str(initialDelta));
add_block('simulink/Math Operations/Gain', [modelName '/Cooling'], 'Gain', num2str(-coolingRate));
add_block('simulink/Sinks/To Workspace', [modelName '/Output'], 'VariableName', 'temperature', 'SaveFormat', 'Timeseries');
add_line(modelName, 'Temperature/1', 'Cooling/1');
add_line(modelName, 'Cooling/1', 'Temperature/1');
add_line(modelName, 'Temperature/1', 'Output/1', 'autorouting', 'on');
simulation = sim(modelName, 'StopTime', num2str(stopTime), 'RelTol', '1e-8', 'AbsTol', '1e-9', 'ReturnWorkspaceOutputs', 'on');
observed = simulation.temperature.Data(end);
simulinkError = abs(observed - expected);
assert(simulinkError < acceptanceTolerance, 'Simulink result outside tolerance');
fprintf('SIMULINK_SMOKE=PASS actual=%.8f error=%.3g\n', observed, simulinkError);
close_system(modelName, 0);
'@

Push-Location -LiteralPath $env:TEMP
try {
    & $matlabCommand.Source -wait -batch ($matlabCode -replace '[\r\n]+', ' ')
    $matlabExitCode = $LASTEXITCODE
}
finally {
    Pop-Location
}
if ($matlabExitCode -ne 0) {
    throw "MATLAB exited with code $matlabExitCode"
}
