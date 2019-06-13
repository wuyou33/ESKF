function [x, P] = updateState(x, P, y, dt)
%UPDATE state estimation and process covariance 
%
    persistent g; g = 9.80665;
    
    persistent Q; % Adjust Q

    Q = blkdiag(zeros(3), 0.08*diag(ones(1,3)), diag(ones(1,3)));

    % Q(1,1) = 0; Q(2,2) = 0; Q(3,3) = 0;
    % Q(4,4) = 0.08; Q(5,5) = 0.08; Q(6,6) = 0.08;
    % Q(7,7) = 1.0; Q(8,8) = 1.0; Q(9,9) = 1.0;

    % Integration model: Update state
    x(1)  = x(1) + dt*x(4);
    x(2)  = x(2) + dt*x(5);
    x(3)  = x(3) + dt*x(6);
    x(4)  = x(4) + dt*(y(1)*(x(7)^2 + x(8)^2 - x(9)^2 - x(10)^2) - y(2)*(2*x(7)*x(10) - 2*x(8)*x(9)) + y(3)*(2*x(7)*x(9) + 2*x(8)*x(10)));
    x(5)  = x(5) + dt*(y(2)*(x(7)^2 - x(8)^2 + x(9)^2 - x(10)^2) + y(1)*(2*x(7)*x(10) + 2*x(8)*x(9)) - y(3)*(2*x(7)*x(8) - 2*x(9)*x(10)));
    x(6)  = x(6) - dt*(g - y(3)*(x(7)^2 - x(8)^2 - x(9)^2 + x(10)^2) + y(1)*(2*x(7)*x(9) - 2*x(8)*x(10)) - y(2)*(2*x(7)*x(8) + 2*x(9)*x(10)));
    x(7)  = x(7) - (dt*x(8)*y(4))/2 - (dt*x(9)*y(5))/2 - (dt*x(10)*y(6))/2;
    x(8)  = x(8) + (dt*x(7)*y(4))/2 + (dt*x(9)*y(6))/2 - (dt*x(10)*y(5))/2;
    x(9)  = x(9) + (dt*x(7)*y(5))/2 - (dt*x(8)*y(6))/2 + (dt*x(10)*y(4))/2;
    x(10) = x(10) + (dt*x(7)*y(6))/2 + (dt*x(8)*y(5))/2 - (dt*x(9)*y(4))/2;
 
 
    as = y(1:3);
    ws = y(4:6);
    q = x(7:10);
    
    % Error-State Jacobian
%     Fn =  [ 1, 0, 0, dt,  0,  0,                                                               0,                                                               0,                                                               0;...
%             0, 1, 0,  0, dt,  0,                                                               0,                                                               0,                                                               0;...
%             0, 0, 1,  0,  0, dt,                                                               0,                                                               0,                                                               0;...
%             0, 0, 0,  1,  0,  0,          dt*(y(2)*(2*x(7)*x(9) + 2*x(8)*x(10)) + y(3)*(2*x(7)*x(10) - 2*x(8)*x(9))),  dt*(y(3)*(x(7)^2 + x(8)^2 - x(9)^2 - x(10)^2) - y(1)*(2*x(7)*x(9) + 2*x(8)*x(10))), -dt*(y(2)*(x(7)^2 + x(8)^2 - x(9)^2 - x(10)^2) + y(1)*(2*x(7)*x(10) - 2*x(8)*x(9)));...
%             0, 0, 0,  0,  1,  0, -dt*(y(3)*(x(7)^2 - x(8)^2 + x(9)^2 - x(10)^2) + y(2)*(2*x(7)*x(8) - 2*x(9)*x(10))),          dt*(y(1)*(2*x(7)*x(8) - 2*x(9)*x(10)) + y(3)*(2*x(7)*x(10) + 2*x(8)*x(9))),  dt*(y(1)*(x(7)^2 - x(8)^2 + x(9)^2 - x(10)^2) - y(2)*(2*x(7)*x(10) + 2*x(8)*x(9)));...
%             0, 0, 0,  0,  0,  1,  dt*(y(2)*(x(7)^2 - x(8)^2 - x(9)^2 + x(10)^2) - y(3)*(2*x(7)*x(8) + 2*x(9)*x(10))), -dt*(y(1)*(x(7)^2 - x(8)^2 - x(9)^2 + x(10)^2) + y(3)*(2*x(7)*x(9) - 2*x(8)*x(10))),          dt*(y(1)*(2*x(7)*x(8) + 2*x(9)*x(10)) + y(2)*(2*x(7)*x(9) - 2*x(8)*x(10)));...
%             0, 0, 0,  0,  0,  0,                                                               1,                                                          dt*y(6),                                                         -dt*y(5);...
%             0, 0, 0,  0,  0,  0,                                                         -dt*y(6),                                                               1,                                                          dt*y(4);...
%             0, 0, 0,  0,  0,  0,                                                          dt*y(5),                                                         -dt*y(4),                                                               1];

    V  = -q2R(q)*skew(as);          % as -> measured accelerations
    Fi = -skew(ws);                 % ws -> measured angular velocities
        
    A_dx = [zeros(3)   eye(3)   zeros(3); ...
            zeros(3)  zeros(3)    V     ; ...
            zeros(3)  zeros(3)    Fi   ]; 

    Fn = eye(9) + A_dx*dt;    

    % Predict covariance
    P = Fn*P*Fn.' + Q; % Q is already Fi*Q*Fi.';
    
end
