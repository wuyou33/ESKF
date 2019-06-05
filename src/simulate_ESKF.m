clc; clear
format long;
%% Load raw data
% try catch structure for debugging
try
   data = csvread("../data/datalog_25.csv");
catch
   % do nothing, just avoid throwing an error
end

%% ESKF Simulation
% Flow Outlier detection
FLOW_LIMIT = 30;

% Initialize state and P
x = zeros(10, 1); x(7) = 1.0; x(3) = 0.06;
%P = zeros(9,9);
P = diag(ones(1,9));

X = [];

% Iterate through all rows of raw data. It is assumed here that
% sensor data has already been collected at the desired frequencies.
% This way, each iteration simulates the arrival of new data from
% a specific sensor
previousTimestamp = 1;
previousFlowTimestamp = 1;

for i = 2 : length(data(:,1))
    timestamp = data(i, 1);
    sensor_data = data(i, 2:end); 
    
    % We can know if sensor data is available via the index and the value
    IMUData = (sensor_data(1) ~= 1000.0) && (sensor_data(2) ~= 1000.0) && (sensor_data(3) ~= 1000.0) && (sensor_data(4) ~= 1000.0) && (sensor_data(5) ~= 1000.0) && (sensor_data(6) ~= 1000.0); 
    accelData = (sensor_data(1) ~= 1000.0 && sensor_data(2) ~= 1000.0 && sensor_data(3) ~= 1000.0) && ~IMUData; 
    rangeData = sensor_data(7) ~= 1000.0; 
    flowData = sensor_data(8) ~= 1000.0 && sensor_data(9) ~= 1000.0;

    sensor_data(1) = sensor_data(1) * 9.80665;
    sensor_data(2) = sensor_data(2) * 9.80665;
    sensor_data(3) = sensor_data(3) * 9.80665;
    
    sensor_data(4) = sensor_data(4) * pi / 180;
    sensor_data(5) = sensor_data(5) * pi / 180;
    sensor_data(6) = sensor_data(6) * pi / 180;
    
    if (IMUData)
        dt = timestamp - data(previousTimestamp,1);
        [x, P] = updateState(x, P, sensor_data, dt);
        previousTimestamp = i;
    end
    if (accelData)
        [x, P] = accelCorrect(x, P, sensor_data);
    end
    if (rangeData)
        [x, P] = rangeCorrect(x, P, sensor_data);
    end
    if (flowData && abs(sensor_data(8)) < FLOW_LIMIT && abs(sensor_data(9)) < FLOW_LIMIT)
        dt = timestamp - data(previousFlowTimestamp,1);
        %sensor_data(8) = -sensor_data(8)/dt;
        %sensor_data(9) = sensor_data(9)/dt;
        %[x, P] = flowCorrect(x, P, sensor_data);
        [x, P] = flowCorrectCrazyflie(x, P, sensor_data, dt);
        previousFlowTimestamp = i;
    end
    %x(10) = 0;
    X = [X, x]; % Log state after estimations

end

%% Plot state evolution

figure;
% plot position estimation
hold on;
grid on;
plot(data(2:end,1), X(1,:)', 'b');
plot(data(2:end,1), X(2,:)', 'r');
plot(data(2:end,1), X(3,:)', 'g');
title('Positions')

figure;
% plot trajectory estimation
hold on;
grid on;
plot(X(1,:)', X(2,:), 'k');
% This might need some tuning
ylim([-2 2])
xlim([-2 2])
title('2D trajectory')

figure;
% plot trajectory estimation
hold on;
grid on;
plot3(X(1,:), X(2,:), X(3,:));
% This might need some tuning
ylim([-2 2])
xlim([-2 2])
zlim([0 1])
view(45,45)
title('3D trajectory')

figure;
% plot velocity estimation
hold on;
grid on;
plot(data(2:end,1), X(6,:)', 'g');
plot(data(2:end,1), X(5,:)', 'r');
plot(data(2:end,1), X(4,:)', 'b');
title('Velocities')

figure;
% plot velocities estimation in imu frame
quats = X(7:10,:);
vels = [];
for i = 1 : length(quats(1,:))
    R = q2R(quats(:, i));
    vels = [vels, R*[X(4,i); X(5,i);X(6,i)]];
end
hold on;
grid on;
plot(data(2:end,1), vels(1,:)', 'b');
plot(data(2:end,1), vels(2,:)', 'r');
plot(data(2:end,1), vels(3,:)', 'g');
title('Local velocities')


figure;
% plot quaternion estimation
hold on;
grid on;
plot(data(2:end,1), X(7,:)', 'k');
plot(data(2:end,1), X(8,:)', 'b');
plot(data(2:end,1), X(9,:)', 'r');
plot(data(2:end,1), X(10,:)', 'g');
title('Quaternion')

figure;
% plot euler angles' estimation
quats = X(7:10,:);
E = [];
for i = 1 : length(quats(1,:))
    e = q2e(quats(:, i));
    E = [E, e];
end
hold on;
grid on;
plot(data(2:end,1), E(1,:)', 'b');
plot(data(2:end,1), E(2,:)', 'r');
plot(data(2:end,1), E(3,:)', 'g');
title('Euler angles')

