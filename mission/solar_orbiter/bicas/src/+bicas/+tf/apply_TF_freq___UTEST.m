%
% matlab.unittest code for function "bicas.tf.apply_TF_freq()".
%
% NOTE: bicas.tf.apply_TF_freq() does not alter the function before/after the
% application of the TF, e.g. de-/re-trending.
%
%
% TERMINOLOGY
% ===========
% TF : Transfer function.
% TS : Time Series. Data in time domain.
%
%
% Author: Erik P G Johansson, IRF, Uppsala, Sweden
% First created 2017-02-13.
% Refactored for matlab.unittest 2021-08-06.
%
classdef apply_TF_freq___UTEST < matlab.unittest.TestCase
% BOGIQ:
% ------
% PROPOSAL: Utility Z(omega) for generating single frequency change.
% PROPOSAL: Automatic test: apply tf + apply inverted TF?
% TODO-NI: How robust is automatic test code in the event of better
%          algorithms? (Hann windows, de-trending, time-domain application
%          of TF, ...)
% PROPOSAL: Use specially-written "equals"-like function that permits
%           (greater) discrepancies at the edge(s).
%   PROPOSAL: Use weighting function.
%
% PROPOSAL: Try all combinations of input signals and TFs.
%   CON: Then needs to manually hardcode the expected result for each combination.
%       CON: Can automatize the derivation of expected results for some TFs.
%           Ex: Delays, tf_constant.
%           CON: Not all tests: Signal=sine + ~arbitrary TF.
%   PROPOSAL: Initialization functions for the respective lists.
    
    
    
    properties(Constant)
        PLOTTING_ENABLED = 0;
        EPSILON = 1e-13;
        %EPSILON = 1e-14;    % Tests fail. /2021-08-06
    end
    
    
    
    properties(TestParameter)
        % Number of samples in time series.
        % NOTE: Want to test both even & odd N, maybe primes.
        N = {100, 101, 29}
        %N = {101}
        
        % Time delay for TFs which represent a delay.
        % NOTE: Only integers.
        nDelaySmpls = {0,1,-1, 5, -5}
        %nDelaySmpls = {-1}
    end
    
    
    
    methods(Test)

        
        
        % Signal: Quadratic function
        % TF    : Constant delay.
        %
        % NOTE: Output signal has discrete jumps due to circular shift.
        function test1(testCase, N, nDelaySmpls)
            dt    = 0.1;
            delay = nDelaySmpls*dt;

            tf = @(omega) bicas.tf.apply_TF_freq___UTEST.tf_delay(...
                omega, delay);

            t      = bicas.tf.apply_TF_freq___UTEST.time_vector_N_dt(...
                N, dt);
            f      = @(t) (0.5*(t-3).^2 + 5);
            y1     = f(t);
            y2_exp = bicas.tf.apply_TF_freq___UTEST.ts_delay_func_discrete(...
                y1, nDelaySmpls);

            bicas.tf.apply_TF_freq___UTEST.complete_test(...
                testCase, {dt, y1, tf}, y2_exp)
        end

        
        
        % Signal: Constant function
        % TF    : Constant Z == 1 (all omega)
        function test2(testCase, N)
            dt = 0.1;

            tf = @(omega) bicas.tf.apply_TF_freq___UTEST.tf_constants(...
                omega, 2, 2);

            t      = bicas.tf.apply_TF_freq___UTEST.time_vector_N_dt(...
                N, dt);
            f1     = @(t) (1 * ones(size(t)) );
            f2     = @(t) (2 * ones(size(t)) );
            y1     = f1(t);
            y2_exp = f2(t);

            bicas.tf.apply_TF_freq___UTEST.complete_test(...
                testCase, {dt, y1, tf}, y2_exp)
        end
        

        
        % Signal: Approximately one non-zero DFT component
        % TF    : Constant Z(!), except tfZ(omega=0). Different time delays
        %         on different frequencies, which produces a chosen time
        %         delay for this specific signal.
        function test3(testCase, N, nDelaySmpls)
            % NOTE: Can not easily automatically derive the output for an
            % arbitrary input signal here (on the subject of combining input
            % signals and TFs).
            
            dt     = 2*pi/N;
            delay = nDelaySmpls * dt;
            omega0 = 1;    % Fits time interval perfectly. Perfectly periodic.

            tf = @(omega) bicas.tf.apply_TF_freq___UTEST.tf_constants(...
                omega, 1, exp(1i*omega0*(-delay)));
            t  = bicas.tf.apply_TF_freq___UTEST.time_vector_N_dt(...
                N, dt);

            f  = @(t) (3+cos(omega0 * (t-pi/5)));

            y1     = f(t);
            y2_exp = bicas.tf.apply_TF_freq___UTEST.ts_delay_func_discrete(...
                y1, nDelaySmpls);

            bicas.tf.apply_TF_freq___UTEST.complete_test(...
                testCase, {dt, y1, tf}, y2_exp)
        end
        

        
        % Signal: Single non-zero DFT component
        % TF    : One delay for all frequencies.
        function test4(testCase, N, nDelaySmpls)
            dt    = 0.1;
            delay = nDelaySmpls*dt;

            tf = @(omega) bicas.tf.apply_TF_freq___UTEST.tf_delay(...
                omega, delay);

            % Exact DFT frequency.  ==> Good match
            omega0 = 2*pi * 5/(N*dt);
            % Arbitrary frequency.  ==> Edge effects, generally
            %omega0 = 2*pi * 1/3;
            % Assert minimum number of oscillation periods in function (in
            % radians).
            assert((N*dt) / (1/omega0) >= 10, 'Bad test config.?')

            t  = bicas.tf.apply_TF_freq___UTEST.time_vector_N_dt(...
                N, dt);
            f = @(t) cos(omega0 * (t-pi/5));

            y1     = f(t);
            y2_exp = bicas.tf.apply_TF_freq___UTEST.ts_delay_func_discrete(...
                y1, nDelaySmpls);

            bicas.tf.apply_TF_freq___UTEST.complete_test(...
                testCase, {dt, y1, tf}, y2_exp)
        end
        

        
        % Signal: Arbitrary function
        % TF    : Delay
        function test5(testCase, N, nDelaySmpls)
            dt    = 0.01;
            delay = nDelaySmpls*dt;

            tf = @(omega) bicas.tf.apply_TF_freq___UTEST.tf_delay(...
                omega, delay);

            t  = bicas.tf.apply_TF_freq___UTEST.time_vector_N_dt(...
                N, dt);

            f      = @(t) exp(t);
            y1     = f(t);
            y2_exp = bicas.tf.apply_TF_freq___UTEST.ts_delay_func_discrete(...
                y1, nDelaySmpls);

            bicas.tf.apply_TF_freq___UTEST.complete_test(...
                testCase, {dt, y1, tf}, y2_exp)
        end



        % Signal: Arbitrary function
        % TF    : Delay
        function test6(testCase, N, nDelaySmpls)
            dt    = 1 / (N-1);
            delay = nDelaySmpls*dt;

            tf = @(omega) bicas.tf.apply_TF_freq___UTEST.tf_delay(...
                omega, delay);

            t  = bicas.tf.apply_TF_freq___UTEST.time_vector_N_dt(...
                N, dt);

            f = @(t) ((t-5).^3 - 20*t + 25);
            y1 = f(t);
            y2_exp = bicas.tf.apply_TF_freq___UTEST.ts_delay_func_discrete(...
                y1, nDelaySmpls);

            bicas.tf.apply_TF_freq___UTEST.complete_test(...
                testCase, {dt, y1, tf}, y2_exp)
        end
        
        

        % Signal: Constant + sine wave
        % TF    : Non-zero only at omega=0.
        function test7(testCase, N)
            dt = 1 / (N-1);
            z0 = -2;

            tf = @(omega) bicas.tf.apply_TF_freq___UTEST.tf_constants(...
                omega, z0, 0);

            t  = bicas.tf.apply_TF_freq___UTEST.time_vector_N_dt(...
                N, dt);

            y1 = 10 * ones(size(t)) + 5 * sin(10*t.^3);            
            % Only keep mean (and multiply by factor).
            y2_exp = z0 * ones(size(y1)) * mean(y1);
            
            bicas.tf.apply_TF_freq___UTEST.complete_test(...
                testCase, {dt, y1, tf}, y2_exp)
        end
        
        
        
    end    % methods

    
    
    methods(Static)
        
        
        % Utility method for test methods.
        %
        % NOTE: Concerning testCase: Method not called by runtests() directly
        % but indirectly via the test methods.
        function complete_test(testCase, argsCa, y2_exp)
            
            y1 = argsCa{2};
            
            %================================
            % CALL bicas.tf.apply_TF_freq
            %================================
            y2_act = bicas.tf.apply_TF_freq( argsCa{:} );
            
            testCase.verifyEqual(size(y1), size(y2_act))

            if bicas.tf.apply_TF_freq___UTEST.PLOTTING_ENABLED
                n = (1:length(y2_exp))';
                
                %==============================================
                % Plot
                % -- Input           into apply_TF_time()
                % -- Actual output   from apply_TF_time()
                % -- Expected output from apply_TF_time()
                %
                % NOTE: All plots are in the time domain.
                %==============================================
                figure
                plot(n, y1,     '-k');   hold on
                plot(n, y2_exp, 'o', 'LineWidth', 2.0)
                plot(n, y2_act, '*')
                legend({'y1', 'y2\_expected', 'y2\_actual'})
                xlabel('Time-domain array index (not t)')
            end

            testCase.verifyEqual(...
                y2_act, y2_exp, ...
                'AbsTol', bicas.tf.apply_TF_freq___UTEST.EPSILON)
        end
        
        
        
        % TF for constant or (almost) constant Z. Implements Z(omega=0)=z0 and
        % Z(omega~=0)=z1.
        %
        % z1 == 0: 
        %   Keeping only the mean and multiplying it by z0 (real).
        %
        % z0 == z1:
        %   Constant TF. Multiply signal by z0.
        %
        %
        % NOTE: Must work for omega=vector.
        % NOTE: z0 should be real.
        function Z = tf_constants(omega, z0, z1)
            assert(isreal(z0))
            
            Z = (omega==0)*z0 + (omega~=0)*z1;
        end



        % TF that delays function, i.e. it is moved in the t+ direction (time
        % domain), i.e. the same time delay (in time units) for all frequencies.
        function Z = tf_delay(omega, delay)
            Z = exp(1i*omega*(-delay));
        end

        
        
        % Delay function (circular shift) by integer numebr of samples.
        %
        % IMPLEMENTATION NOTE: One can in principle use a function that
        % circular-shifts an analytical signal (function handle). However, if
        % one delays the signal by integer*dt, then rounding error can lead to
        % that a y value that is shifted to be on the boundary ends up on the
        % wrong boundary due to rounding error.
        function y2 = ts_delay_func_discrete(y1, delaySmpls)
            y2 = circshift(y1, delaySmpls);
        end



        % Function for creating timestamps vector.
        function [t, t2] = time_vector_N_dt(N,dt)
            t2 = (N-1)*dt;
            t  = [0 : dt : t2]';
        end

        
        
    end    % methods
    


end   % classdef
