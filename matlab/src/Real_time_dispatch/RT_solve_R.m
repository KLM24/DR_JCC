function [ RT_sol ] = RT_solve_R(si, y1, ru, rd)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Energy and Reserve Dispatch with Distributionally Robust Joint Chance Constraints
%   Christos Ordoudis, Viet Anh Nguyen, Daniel Kuhn, Pierre Pinson
%
%   This script solves the real time dispatch program
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

yalmip('clear')

% Getting the number of thermals power plants, wind farms, scenarions,
% transmission lines and nodes
Nunits = size(si.Pmax,1);
Nwind = size(si.Wmax,1);
Nlines = size(si.F,1);
Nnodes = size(si.AG,1);
Nloads = size(si.D,1);

% Definition of variables
y2 = sdpvar(Nunits, 1); % Real-time power production from thermal power plants
lshed = sdpvar(Nloads, 1); % Real-time load shedding
wsp = sdpvar(Nwind, 1);  % Real-time wind spilling
res_inc = sdpvar(Nunits, 1); % Real-time reserve increase
fi_real = sdpvar(Nnodes, 1); % Day-ahead injection at each node

% Constraints set
CS = [];
CS = [CS, si.Pmin <= y1 + y2 <= si.Pmax, -rd - res_inc <= y2 <= ru, -si.F <= si.PTDF*fi_real <= si.F, sum(fi_real) == 0];
CS = [CS, si.AG*(y1 + y2) + si.AW * si.DiagWmax*si.Wreal - si.AD*(si.D - lshed) - si.AW * wsp == fi_real, 0 <= lshed <= si.D, 0<= res_inc <= y1 - rd];
CS = [CS, 0 <= wsp <= si.DiagWmax*si.Wreal];
CS = [CS, 0 <= si.PG * (y1+y2) <= si.FP];


% Build the onjective function 
Obj_real = si.c' * (y1+y2) + si.cl*ones(Nloads, 1)'*lshed + si.cw*ones(Nwind, 1)'*wsp + si.cr*ones(Nunits, 1)'*res_inc; 

% Optimization options
optim_options = sdpsettings('solver', 'gurobi' ,'gurobi.TimeLimit',500,'verbose',0);

% Solve
sol = optimize(CS, Obj_real, optim_options);

RT_sol.p_RT = y1 + value(y2);
RT_sol.lshed_RT = value(lshed);
RT_sol.wsp_RT = value(wsp);
RT_sol.flow_RT = si.PTDF*value(fi_real);
RT_sol.Obj_RT = value(Obj_real);
RT_sol.Flag = sol.problem;

end

