# MATLAB 与 Simulink 环境验算全流程

本流程用独立的热水自然冷却算例，验证 Windows 上能否启动 MATLAB、调用 Control System Toolbox、求解和绘图，并运行 Simulink。算例仅用于验证环境。

## 1. 初始化与验收标准

- 时间单位为分钟，温差单位为摄氏度。初始温差为 40 °C，冷却系数为 0.1 min⁻¹，运行至第 10 分钟。
- 解析值为 40 × exp(−1)，约 14.71517765 °C。MATLAB 和 Simulink 各自与该值比较，绝对误差均须小于 1e-5 °C。
- 控制台须看到 CONTROL_TOOLBOX=PASS、MATLAB_ODE_AND_PLOT=PASS 和 SIMULINK_SMOKE=PASS。MATLAB 退出码须为 0。
- 初始化值集中在脚本开头。每轮从新 MATLAB 进程启动。图窗在后台创建并检查采样数。Simulink 模型在内存中建立，完成后关闭。

## 2. 一次运行

可从仓库根目录直接执行 [scripts/verify-matlab.ps1](../scripts/verify-matlab.ps1)，也可在 Windows PowerShell 中执行下方完整命令。脚本进入系统临时目录运行，并在退出后恢复原目录。无需另外创建项目脚本或保存模型。

```powershell
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
```

## 3. 失败怎么查

1. 找不到 MATLAB 时，先检查 Get-Command matlab 的结果。此前验证的版本为 R2022a。
2. 启动后失败时，记录第一条错误和最后一个 PASS。根据错误检查工具箱是否存在、许可证是否有效、输出格式是否变化。
3. 如果修改了 MATLAB 内联脚本，保留语句末尾的分隔符。这一命令会把多行代码折成单行，行尾注释和依赖换行分隔的语句会影响执行。
4. 出现所有 PASS 后仍要等待 MATLAB 退出并核对退出码。故障修复后从第 2 节重跑，保留上一次失败原因。

## 4. 交接记录

记录实际启动的 MATLAB 版本、三项 PASS、两份终点数值及误差、退出码和未通过项。2026 年 11 月 20 日验证环境为 MATLAB R2022a，Control System Toolbox 10.11.1，Simulink 10.5。两种求解结果均为 14.71517765 °C。

环境验算结果仅用于检查工具运行状态。
