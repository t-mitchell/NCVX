 function varargout = solveQP(varargin)
%   solveQP:
%       Convenience wrapper for any quadprog interface QP solver.  This
%       wrapper function will suppress any warnings from the underlying
%       quadprog solver and catch any errors that are thrown and rethrow
%       them as specific error types, such that they can be caught and
%       dealt with accordingly.
%
%   solveQP also keeps tracks of the number of times:
%       - solveQP has called quadprog
%       - quadprog has thrown an error or returned an invalid result;
%         a result is considered invalid if it is exactly zero, contains
%         infs/NaNs, or is empty.
%
%   To access this metadata:
%   [requests,errors] = solveQP('counts');
%
%   To reset these counters:
%   clear solveQP;
%
%   INPUT:  
%       same arguments as quadprog plus an additional field to
%       quadprog's options struct: 
% 
%       .suppress_warnings                  [logical | {true}]
%           suppress all warnings and error messages generated by 
%           quadprog (except for license issues)
% 
%   OUTPUT: 
%       X and LAMBDA output arguments from full call to quadprog:
%       [X,FVAL,EXITFLAG,OUTPUT,LAMBDA] = quadprog(...)
% 
%                                           
%   If you publish work that uses or refers to GRANSO, please cite the 
%   following paper: 
%
%   [1] Frank E. Curtis, Tim Mitchell, and Michael L. Overton 
%       A BFGS-SQP method for nonsmooth, nonconvex, constrained 
%       optimization and its evaluation using relative minimization 
%       profiles, Optimization Methods and Software, 32(1):148-181, 2017.
%       Available at https://dx.doi.org/10.1080/10556788.2016.1208749
%
%   For comments/bug reports, please visit the GRANSO GitLab webpage:
%   https://gitlab.com/timmitchell/GRANSO
%
%   solveQP.m introduced in GRANSO Version 1.0.
%
% =========================================================================
% |  GRANSO: GRadient-based Algorithm for Non-Smooth Optimization         |
% |  Copyright (C) 2016 Tim Mitchell                                      |
% |                                                                       |
% |  This file is part of GRANSO.                                         |
% |                                                                       |
% |  GRANSO is free software: you can redistribute it and/or modify       |
% |  it under the terms of the GNU Affero General Public License as       |
% |  published by the Free Software Foundation, either version 3 of       |
% |  the License, or (at your option) any later version.                  |
% |                                                                       |
% |  GRANSO is distributed in the hope that it will be useful,            |
% |  but WITHOUT ANY WARRANTY; without even the implied warranty of       |
% |  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the        |
% |  GNU Affero General Public License for more details.                  |
% |                                                                       |
% |  You should have received a copy of the GNU Affero General Public     |
% |  License along with this program.  If not, see                        |
% |  <http://www.gnu.org/licenses/agpl.html>.                             |
% =========================================================================
% Update (Buyun): replace quadprog with qpalm

    persistent requests;
    persistent errors;

    if isempty(requests)
        requests    = 0;
        errors      = 0;
    end
    
    if nargin < 4 && nargin > 0 && strcmpi(varargin{1},'counts')
        varargout   = {requests,errors};
        return
    end
    
    suppress_warnings = true;
%     if nargin > 9
%         opts = varargin{10};
%         if isfield(opts,'suppress_warnings')
%             suppress_warnings = opts.suppress_warnings;
%         end
%         if isfield(opts,'QPsolver')
%             QPsolver = opts.QPsolver;
%         end
%     end 

    if isstruct(varargin{end})  
        opts = varargin{end};
        if isfield(opts,'suppress_warnings')
            suppress_warnings = opts.suppress_warnings;
        end
        if isfield(opts,'QPsolver')
            QPsolver = opts.QPsolver;
        end
    end
    
    if suppress_warnings
        warning_state = warning;
        warning off
    end
    try
        requests = requests + 1;
        
        % MATLAB default solver
        if (strcmp(QPsolver,'quadprog'))
%             newvarargin = varargin{:};
%             newvarargin = rmfield(newvarargin{end},'QPsolver');
            [X,~,flag,output,LAMBDA] = quadprog(varargin{1:end-1},rmfield(varargin{end},'QPsolver'));%% Solve with qpalm
            varargout = {X,LAMBDA};
        % QPALM solver
        elseif (strcmp(QPsolver,'qpalm'))   
%             newvarargin = varargin{:};
%             newvarargin = rmfield(newvarargin{end},'QPsolver');
            solver = qpalm;
            settings = solver.default_settings();
            %IMPORTANT: set nonconvex to true for nonconvex QPs
            settings.nonconvex = false;
            
            solver.setup(varargin{1:end-1},rmfield(varargin{end},'QPsolver'));
            res = solver.solve();
            % NOTE: the info of LAMBDA/res.y is not used in the GRANSO package
            varargout = {res.x,res.y};
            X = res.x;
        end
        
    catch err
        errors = errors + 1;
        ME = MException('GRANSO:quadprogError','quadprog threw an error.');
        ME = addCause(ME, err);
        ME.throw();
    end
    
    if suppress_warnings
        warning(warning_state);
    end
    
    if isempty(X) || any(isinf(X) | isnan(X)) 
        errors = errors + 1;
        error(  'GRANSO:quadprogAnswerNumericallyInvalid',  ...
                'quadprog returned numerically invalid answer.');
%     elseif nnz(X) < 1 
%         errors = errors + 1;
%         error(  'GRANSO:quadprogReturnedExactlyZero',       ...
%                 'quadprog returned exactly zero.');
    end
 end