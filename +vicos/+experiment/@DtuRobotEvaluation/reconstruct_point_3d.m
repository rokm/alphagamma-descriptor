function pt3d = reconstruct_point_3d (camera1, camera2, pt1, pt2)
    % pt3d = RECONSTRUCT_POINT_3D (camera1, camera2, pt1, pt2)
    %
    % Reconstructs a 3-D point from a pair of 2-D correspondences.
    %
    % Input:
    %  - camera1: 3x4 projective matrix for first camera
    %  - camera2: 3x4 projective matrix for second camera
    %  - pt1: 1x2 vector with image coordinates in first image
    %  - pt2: 1x2 vector with image coordinates in second image
    %
    % Output:
    %  - pt3d: reconstructed 3-D point
    %  - err: estimated reprojection error
    
    %% Obtain initial solution with help of direct linear transformation
    A = [ camera1(1,:) - pt1(1)*camera1(3,:);
          camera1(2,:) - pt1(2)*camera1(3,:);
          camera2(1,:) - pt2(1)*camera2(3,:);
          camera2(2,:) - pt2(2)*camera2(3,:) ];
    [ ~, ~, u ] = svd(A);
    pt3d = u(1:3,end) / u(4,end);
    
    %% Non-linear least-squares refinement with Levenberg-Marquardt
    %opts = optimoptions(@lsqnonlin, 'Algorithm', 'levenberg-marquardt', 'SpecifyObjectiveGradient', true, 'display', 'off');
    %pt3d = lsqnonlin(@(x) reprojection_error(x, { camera1, camera2, pt1, pt2 }), pt3d, [], [], opts);
    
    pt3d = marquardt(@reprojection_error, pt3d, [ 1, 1e-12, 1e-12, 1000 ], { camera1, camera2, pt1, pt2 });
end

function [ F, J ] = reprojection_error (pt3d, params)
    % [ F, J ] = REPROJECTION_ERROR (pt3d, camera1, camera2, pt1, pt2)
    %
    % Computes the objective function (reprojection error) and its
    % derivatives. Used with Levenberg-Marquardt optimization in 3-D point
    % reconstruction.
    %
    % Input:
    %  - pt3d: 3x1 vector of currently estimated 3-D coordinates
    %  - camera1: 3x4 projective matrix for first camera
    %  - camera2: 3x4 projective matrix for second camera
    %  - pt1: 1x2 vector with image coordinates in first image
    %  - pt2: 1x2 vector with image coordinates in second image
    %
    % Output:
    %  - F: 4x1 vector of objective function values (dx and dy for both
    %    cameras)
    %  - J: 4x3 Jacobian matrix (derivatives of dx and dy with respect to
    %    estimated 3-D coordinates X, Y, and Z)
    
    % Decode parameters
    camera1 = params{1};
    camera2 = params{2};
    pt1 = params{3};
    pt2 = params{4};
    
    % Project current estimation to both images
    q1 = camera1 * [ pt3d; 1 ];
    q2 = camera2 * [ pt3d; 1 ];
    
    % Objective [ dx1, dy1, dx2, dy2 ]'
    F = [ q1(1:2)/q1(3) - pt1;
          q2(1:2)/q2(3) - pt2; ];
    
    if nargout > 1
        % Derivatives of objective w.r.t. X, Y, and Z coordinates of the
        % estimated 3d point
        J = [ (q1(3)*camera1(1,1:3) - q1(1)*camera1(3,1:3))/q1(3)^2;
              (q1(3)*camera1(2,1:3) - q1(2)*camera1(3,1:3))/q1(3)^2;
              (q2(3)*camera2(1,1:3) - q2(1)*camera2(3,1:3))/q2(3)^2;
              (q2(3)*camera2(2,1:3) - q2(2)*camera2(3,1:3))/q2(3)^2;
            ];
    end
end

%% Levenberg-Marquardt implementation
% The code velow is part of the toolbox immoptibox which was written by 
% Hans Bruun Nielsen from Department of Mathematics and Mathematical 
% Modelling, Technical University of Denmark.
%
% It turns out to have significantly less overhead than using LSQNONLIN().

function [X, info, perf ] = marquardt (fun, x0, opts, varargin)
    %MARQUARDT  Levenberg-Marquardt's method for least squares.
    % Find  xm = argmin{F(x)} , where  x  is an n-vector and
    % F(x) = .5 * sum(f_i(x)^2) .
    % The functions  f_i(x) (i=1,...,m) and the Jacobian matrix  J(x)
    % (with elements  J(i,j) = Df_i/Dx_j ) must be given by a MATLAB
    % function with declaration
    %            function  [f, J] = fun(x,p1,p2,...)
    % p1,p2,... are parameters of the function.  In connection with
    % nonlinear data fitting they may be arrays with coordinates of
    % the data points.
    %
    % Call
    %    [X, info] = marquardt(fun, x0)
    %    [X, info] = marquardt(fun, x0, opts, p1,p2,...)
    %    [X, info, perf] = marquardt(.....)
    %
    % Input parameters
    % fun  :  Handle to the function.
    % x0   :  Starting guess for  xm .
    % opts :  Vector with five elements.
    %         opts(1)  used in starting value for Marquardt parameter:
    %             mu = opts(1) * max(A0(i,i))  with  A0 = J(x0)'*J(x0)
    %         opts(2:4)  used in stopping criteria:
    %             ||F'||inf <= opts(2)                     or
    %             ||dx||2 <= opts(3)*(opts(3) + ||x||2)    or
    %             no. of iteration steps exceeds  opts(4) .
    %         opts(5)  lower bound on mu:
    %             mu = opts(5) * max(A(i,i))  with  A = J(x)'*J(x)
    %         Default  opts = [1e-3 1e-4 1e-8 100 1e-14]
    %         If the input opts has less than 5 elements, it is
    %         augmented by the default values.
    % p1,p2,..  are passed directly to the function FUN .
    %
    % Output parameters
    % X    :  If  perf  is present, then array, holding the iterates
    %         columnwise.  Otherwise, computed solution vector.
    % info :  Performance information, vector with 6 elements:
    %         info(1:4) = final values of
    %             [F(x)  ||F'||inf  ||dx||2  mu/max(A(i,i))] ,
    %           where  A = J(x)'*J(x) .
    %         info(5) = no. of iteration steps
    %         info(6) = 1 : Stopped by small gradient
    %                   2 :  Stopped by small x-step
    %                   3 :  No. of iteration steps exceeded
    %                  -1 :  x is not a real valued vector
    %                  -2 :  f is not a real valued column vector
    %                  -3 :  J is not a real valued matrix
    %                  -4 :  Dimension mismatch in x, f, J
    %                  -5 :  Overflow during computation
    % perf :  Array, holding
    %         perf(1,:) = values of  F(x)
    %         perf(2,:) = values of  || F'(x) ||inf
    %         perf(3,:) = mu-values.
    %
    % Method
    % Gauss-Newton with Levenberg-Marquardt damping, see eg
    % H.B. Nielsen, "Damping parameter in Marquardt's method",
    % IMM-REP-1999-05, IMM, DTU, April 1999.
    
    % Version 04.05.18.  hbn(a)imm.dtu.dk
    
    % Check parameters and function call
    if  nargin < 3
        opts = [];
    end
    opts = checkopts(opts, [ 1e-3, 1e-4, 1e-8, 100, 1e-14 ]);
    
    if  nargin < 2
        stop = -1;
    else
        [ stop, x ] = checkx(x0);
        if ~stop
            [ stop, F, f, J ] = checkfJ(fun,x0,varargin{:});
        end
    end
    
    if ~stop
        g = J'*f;
        ng = norm(g, inf);
        A = J'*J;
        if isinf(ng) || isinf(norm(A(:), inf))
            stop = -5;
        end
    else
        F = NaN;
        ng = NaN;
    end
    
    if  stop
        X = x0;
        perf = [];
        info = [ F, ng, 0, opts(1), 0, stop ];
        return;
    end
    
    %  Finish initialization
    mu = opts(1) * max(diag(A));
    kmax = opts(4);
    Trace = nargout > 2;
    if Trace
        X = repmat(x,1,kmax+1);
        perf = repmat([F; ng; mu], 1, kmax+1);
    end
    k = 1;
    nu = 2;
    nh = 0;
    stop = 0;
    
    % Iterate
    while ~stop
        if ng <= opts(2)
            stop = 1;
        else
            mu = max(mu, opts(5)*max(diag(A)));
            [ h, mu ] = geth(A, g, mu);
            nh = norm(h);
            nx = opts(3) + norm(x);
            if  nh <= opts(3)*nx
                stop = 2;
            end
        end
        
        if ~stop
            xnew = x + h;
            h = xnew - x;
            dL = (h'*(mu*h - g))/2;
            [ stop, Fn, fn, Jn ] = checkfJ(fun, xnew, varargin{:});
            if ~stop
                k = k + 1;
                dF = F - Fn;
                
                if  Trace
                    X(:,k) = xnew;
                    perf(:,k) = [ Fn, norm(Jn'*fn,inf), mu]';
                end
                
                if dL > 0 && dF > 0
                    % Update x and modify mu
                    x = xnew;
                    F = Fn;
                    J = Jn;
                    f = fn;
                    A = J'*J;
                    g = J'*f;
                    ng = norm(g, inf);
                    mu = mu * max(1/3, 1 - (2*dF/dL - 1)^3);
                    nu = 2;
                else
                    % Same  x, increase  mu
                    mu = mu*nu;
                    nu = 2*nu;
                end
                
                if k > kmax
                    stop = 3;
                elseif  isinf(ng) || isinf(norm(A(:),inf))
                    stop = -5;
                end
            end
        end
    end
    
    %  Set return values
    if  Trace
        X = X(:, 1:k);
        perf = perf(:,1:k);
    else
        X = x;
    end
    
    if  stop < 0
        F = NaN;
        ng = NaN;
    end
    
    info = [ F, ng, nh, mu/max(diag(A)), k-1, stop ];
end

function opts = checkopts (opts, default)
    %function  opts = checkopts(opts, default)
    %
    % CHECKOPTS  Replace illegal values by default values.
    %
    % Version 10.11.03
    % This code is part of the toolbox immoptibox which was written by Hans Bruun Nielsen.
    % Department of Mathematics and Mathematical Modelling, Technical University of Denmark.
    
    a = default;
    la = length(a);
    lo = length(opts);
    
    for i = 1:min(la,lo)
        oi = opts(i);
        if  isreal(oi) && ~isinf(oi) && ~isnan(oi) && oi > 0
            a(i) = opts(i);
        end
    end
    if lo > la
        a = [ a, 1];
    end % for linesearch purpose
    
    opts = a;
end

function [ err, x, n ] = checkx (x0)
    %function  [err, x,n] = checkx(x0)
    %
    % CHECKX  Check vector
    %
    % Version 10.11.03
    % This code is part of the toolbox immoptibox which was written by Hans Bruun Nielsen.
    % Department of Mathematics and Mathematical Modelling, Technical University of Denmark.
    
    err = 0;
    sx = size(x0);
    n = max(sx);
    
    if  min(sx) ~= 1 || ~isreal(x0) || any(isnan(x0(:))) || isinf(norm(x0(:)))
        err = -1;
        x = [];
    else
        x = x0(:);
    end
end

function [ err, F, f, J ] = checkfJ (fun, x, varargin)
    %function  [err, F,f,J] = checkfJ(fun,x,varargin)
    %
    % CHECKFJ  Check Matlab function which is called by a
    % nonlinear least squares solver.
    %
    % Version 10.11.03
    % This code is part of the toolbox immoptibox which was written by Hans Bruun Nielsen.
    % Department of Mathematics and Mathematical Modelling, Technical University of Denmark.
        
    err = 0;
    F = NaN;
    n = length(x);
    
    if  nargout > 3
        % Check f and J
        [ f, J ] = feval(fun, x, varargin{:});
        
        sf = size(f);
        sJ = size(J);
        
        if sf(2) ~= 1 || ~isreal(f) || any(isnan(f(:))) || any(isinf(f(:)))
            err = -2;
            return;
        end
        
        if ~isreal(J) || any(isnan(J(:))) || any(isinf(J(:)))
            err = -3;
            return;
        end
        
        if sJ(1) ~= sf(1) || sJ(2) ~= n
            err = -4;
            return;
        end    
    else
        % only check  f
        f = feval(fun, x, varargin{:});
        
        sf = size(f);
        
        if sf(2) ~= 1 || ~isreal(f) || any(isnan(f(:))) || any(isinf(f(:)))
            err = -2;
            return;
        end
    end
    
    % Objective function
    F = (f'*f)/2;
    
    if isinf(F)
        err = -5;
    end
end

function [h, mu] = geth (A,g,mu)
    % function  [h, mu] = geth(A,g,mu)
    %
    % Solve  (Ah + mu*I)h = -g  with possible adjustment of  mu
    %
    % Version 10.11.03
    % This code is part of the toolbox immoptibox which was written by Hans Bruun Nielsen.
    % Department of Mathematics and Mathematical Modelling, Technical University of Denmark.
    %
    % Factorize with check of pos. def.
    n = size(A,1);
    chp = 1;
    while chp
        [ R, chp ] = chol(A + mu*eye(n));
        if chp == 0  % check for near singularity
            chp = rcond(R) < 1e-15;
        end
        if chp
            mu = 10*mu;
        end
    end
    
    % Solve (R'*R)h = -g
    h = R \ (R' \ (-g));
end