%
% "Encode" the demultiplexer part of the BIAS subsystem.
% See
%   bicas.proc.L1L2.demuxer.main(), and
%   bicas.proc.L1L2.BLTS_src_dest
%
%
% NOTE
% ====
% It is in principle arbitrary (probably) how the GND and "2.5V Ref" signals,
% which are generated by the instrument, should be represented in the datasets,
% since the datasets assume that only assumes signals from the antennas. The
% implementation classifies them as antennas, including for diffs, but the
% signalTypeCategory specifies that they should be calibrated differently. In
% principle, one could represent unknown signals (unknown mux mode) as antenna
% signals too.
% --
% Demultiplexer is designed to not be aware of that TDS only digitizes BLTS 1-3
% (not 4-5) and does not need to be.
%
%
% DEFINITIONS
% ===========
% See bicas.proc.L1L2.cal, bicas.proc.L1L2.demuxer_latching_relay.
%
%
% Author: Erik P G Johansson, IRF, Uppsala, Sweden
% First created 2019-11-18
%
classdef demuxer
    % PROPOSAL: Change fieldname <routing>.src
    %   NOTE: Can not use ASR/AS ID. Does not cover all sources.
    %   PROPOSAL: .signalSource
    % PROPOSAL: Change fieldname <routing>.dest
    %   PROOPSAL: .datasetAsId
    
    
    
    properties(Access=private, Constant)
        
        % IMPLEMENTATION NOTE: Reasons to pre-define
        %   (1) bicas.proc.L1L2.BLTS_src_dest objects, and
        %   (2) structs created by
        % bicas.proc.L1L2.demuxer.routing (consisting of
        % bicas.proc.L1L2.BLTS_src_dest objects):
        % ** Only makes constructor calls when bicas.proc.L1L2.demuxer is
        %    (statically) initialized, not every time the
        %    bicas.proc.L1L2.demuxer.main function is called.
        %    ==> Faster
        % ** Makes all necessary calls bicas.proc.L1L2.BLTS_src_dest constructor
        %    immediately, regardless of for which arguments the
        %    bicas.proc.L1L2.demuxer.main function is called (in particular mux
        %    mode).
        %    ==> Tests more code immediately.
        %    ==> Finds routing bugs faster.
        
        SRC_DC_V1  = bicas.proc.L1L2.BLTS_src_dest('DC single', [1]);
        SRC_DC_V2  = bicas.proc.L1L2.BLTS_src_dest('DC single', [2]);
        SRC_DC_V3  = bicas.proc.L1L2.BLTS_src_dest('DC single', [3]);
        SRC_DC_V12 = bicas.proc.L1L2.BLTS_src_dest('DC diff',   [1,2]);
        SRC_DC_V13 = bicas.proc.L1L2.BLTS_src_dest('DC diff',   [1,3]);
        SRC_DC_V23 = bicas.proc.L1L2.BLTS_src_dest('DC diff',   [2,3]);
        SRC_AC_V12 = bicas.proc.L1L2.BLTS_src_dest('AC diff',   [1,2]);
        SRC_AC_V13 = bicas.proc.L1L2.BLTS_src_dest('AC diff',   [1,3]);
        SRC_AC_V23 = bicas.proc.L1L2.BLTS_src_dest('AC diff',   [2,3]);

        % Define constants, each one representing different routings.
        ROUTING_DC_V1  = bicas.proc.L1L2.demuxer.routing('DC single', [1]);
        ROUTING_DC_V2  = bicas.proc.L1L2.demuxer.routing('DC single', [2]);
        ROUTING_DC_V3  = bicas.proc.L1L2.demuxer.routing('DC single', [3]);
        ROUTING_DC_V12 = bicas.proc.L1L2.demuxer.routing('DC diff',   [1,2]);
        ROUTING_DC_V13 = bicas.proc.L1L2.demuxer.routing('DC diff',   [1,3]);
        ROUTING_DC_V23 = bicas.proc.L1L2.demuxer.routing('DC diff',   [2,3]);
        ROUTING_AC_V12 = bicas.proc.L1L2.demuxer.routing('AC diff',   [1,2]);
        ROUTING_AC_V13 = bicas.proc.L1L2.demuxer.routing('AC diff',   [1,3]);
        ROUTING_AC_V23 = bicas.proc.L1L2.demuxer.routing('AC diff',   [2,3]);

        ROUTING_25VREF_1_TO_DC_V1     = bicas.proc.L1L2.demuxer.routing('2.5V Ref',  [], 'DC single', [1]);
        ROUTING_25VREF_2_TO_DC_V2     = bicas.proc.L1L2.demuxer.routing('2.5V Ref',  [], 'DC single', [2]);
        ROUTING_25VREF_3_TO_DC_V3     = bicas.proc.L1L2.demuxer.routing('2.5V Ref',  [], 'DC single', [3]);
        ROUTING_GND_1_TO_V1_LF        = bicas.proc.L1L2.demuxer.routing('GND',       [], 'DC single', [1]);
        ROUTING_GND_2_TO_V2_LF        = bicas.proc.L1L2.demuxer.routing('GND',       [], 'DC single', [2]);
        ROUTING_GND_3_TO_V3_LF        = bicas.proc.L1L2.demuxer.routing('GND',       [], 'DC single', [3]);
        ROUTING_UNKNOWN_1_TO_NOTHING  = bicas.proc.L1L2.demuxer.routing('Unknown',   [], 'Nowhere',   []);
        ROUTING_UNKNOWN_2_TO_NOTHING  = bicas.proc.L1L2.demuxer.routing('Unknown',   [], 'Nowhere',   []);
        ROUTING_UNKNOWN_3_TO_NOTHING  = bicas.proc.L1L2.demuxer.routing('Unknown',   [], 'Nowhere',   []);
%         ROUTING_UNKNOWN_1_TO_V1_LF    = bicas.proc.L1L2.demuxer.routing('Unknown',   [], 'DC single', [1]);
%         ROUTING_UNKNOWN_2_TO_V2_LF    = bicas.proc.L1L2.demuxer.routing('Unknown',   [], 'DC single', [2]);
%         ROUTING_UNKNOWN_3_TO_V3_LF    = bicas.proc.L1L2.demuxer.routing('Unknown',   [], 'DC single', [3]);
        % NOTE: BLTS 4 & 5 are never unknown.
        
        % Table to connect BLTS destinations with ASR struct fieldnamnes (FN).
        BLTS_DEST_ASR_FN_TABLE = {...
            bicas.proc.L1L2.demuxer.SRC_DC_V1,  'dcV1'; ...
            bicas.proc.L1L2.demuxer.SRC_DC_V2,  'dcV2'; ...
            bicas.proc.L1L2.demuxer.SRC_DC_V3,  'dcV3'; ...
            bicas.proc.L1L2.demuxer.SRC_DC_V12, 'dcV12'; ...
            bicas.proc.L1L2.demuxer.SRC_DC_V13, 'dcV13'; ...
            bicas.proc.L1L2.demuxer.SRC_DC_V23, 'dcV23'; ...
            bicas.proc.L1L2.demuxer.SRC_AC_V12, 'acV12'; ...
            bicas.proc.L1L2.demuxer.SRC_AC_V13, 'acV13'; ...
            bicas.proc.L1L2.demuxer.SRC_AC_V23, 'acV23'; ...
            };
        
        ASR_FIELDNAMES_CA = bicas.proc.L1L2.demuxer.BLTS_DEST_ASR_FN_TABLE(:, 2);
    end



    methods(Static, Access=public)
        
        
        
        % Function that "encodes" the demultiplexer part of the BIAS subsystem.
        % For a specified mux mode and demuxer latching relay setting, it
        % determines/encodes
        % (1) which (physical) input signal (Antennas, GND, "2.5V Ref", unknown)
        %     is routed to which physical output signal (BLTS)
        %       NOTE: This is needed for calibration.
        % (2) as what ASR (if any) should the BLTS be represented in the
        %     datasets,
        % (3) derive the ASRs (samples) from the ASRs which have not been set.
        %       NOTE: This derivation from fully calibrated ASR samples only
        %       requires addition/subtraction of ASRs. It does not require any
        %       sophisticated/non-trivial calibration since the relationships
        %       between the ASRs are so simple. The only consideration is that
        %       DC diffs have higher accurracy than DC singles, and should have
        %       precedence when deriving ASRs.
        %
        % NOTE: This code does NOT handle the equivalent of demultiplexer
        % multiplication of the BLTS signal (alpha, beta, gamma in the BIAS
        % specification). It is assumed that the supplied BLTS samples have been
        % calibrated to account for this already.
        % 
        % 
        % USAGE
        % =====
        % The function is meant to be called in two different ways, typically
        % twice for any single time period with samples:
        % (1) To obtain signal type info needed for how to calibrate every
        %     BIAS-LFR/TDS signal (BIAS_i) signal given any demux mode.
        % (2) To derive the complete set of ASR samples from the given BLTS
        %     samples.
        %
        %
        % RATIONALE
        % =========
        % Meant to collect all hard-coded information about the demultiplexer
        % routing of signals in the BIAS specification, Table 4.
        %
        %
        % EDGE CASES
        % ==========
        % Function must be able to handle:
        % ** demuxMode = NaN                                   
        %    Unknown demux mode, e.g. due to insufficient HK time coverage.
        % ** BLTS 1-3 signals labelled as "GND" or "2.5V Ref".
        %    Demux modes 5-7.
        %
        %
        % ARGUMENTS
        % =========
        % demuxMode          : Scalar value. Demultiplexer mode.
        %                      NOTE: Can be NaN to represent unknown demux mode.
        %                      Implies that AsrSamplesVolt fields are correctly
        %                      sized with NaN values.
        % dlrUsing12         : See bicas.proc.L1L2.demuxer_latching_relay.
        % bltsSamplesAVolt   : Cell array of vectors/matrices, length 5.
        %                      {iBlts} = Vector/matrix with sample values
        %                      for that BLTS channel, calibrated as for ASR.
        % --
        % NOTE: There is no argument for diff gain since this function does not
        % calibrate/multiply signals by factor.
        %
        %
        % RETURN VALUES
        % =============
        % BltsSrcArray   : Array of bicas.proc.L1L2.BLTS_src_dest objects.
        %                  (iBlts) = Represents the origin of the corresponding
        %                  BLTS.
        % AsrSamplesVolt : Samples for all ASRs (singles, diffs) which can
        %                  possibly be derived from the BLTS (BIAS_i). Those
        %                  which can not be derived are correctly sized
        %                  containing only NaN. Struct with fields.
        %                  NOTE: See "EDGE CASES".
        % --
        % NOTE: Separate names bltsSamplesAVolt & AsrSamplesAVolt to denote that
        % they are organized by BLTS and ASRs.
        %
        function [BltsSrcArray, AsrSamplesAVolt] = main(demuxMode, dlrUsing12, bltsSamplesAVolt)
            % PROPOSAL: Function name that implies constant settings (MUX_SET at least; DIFF_GAIN?!).
            %   invert
            %   main
            %   demux, demultiplex
            %
            % PROPOSAL: Split into two functions.
            %   (1) Function that returns routing and calibration information
            %   (2) Function that derives the missing ASRs (complements struct)
            %       NOTE: DC and AC are separate groups of signals. ==> Simplifies.
            %   NOTE: Needs to use (e.g.) non-existence of field as indication that field has not been derived.
            %           ==> Must set only non-existent fields to NaN.
            %   CON: Only pure data modes should be complemented as far as
            %        possible. Uncertain how to handle other modes (mux=5,6,7).
            %       Ex: mux=5. V1,V2,V3=2.5VRef. but may still want to keep
            %           V12,V13,V23=NaN. Maybe...
            %   CON: Might be harder than it seems.
            %       PRO: Unclear which assumptions to make without using knowledge of the mux table, in which case one
            %       does not want to split up the function in two (does not want to split up the knowledge of the mux
            %       table in two).
            %       CON: Only four relationships between DC ASRs. Only Vxy=f(Vyz,Vxz) (diff as a function of diffs) has
            %            preference over other relationships due to higher precision.
            %
            % PROPOSAL: Log message for mux=NaN.
            
            % ASSERTIONS
            assert(isscalar(demuxMode))
            assert(isscalar(dlrUsing12))
            assert(iscell(bltsSamplesAVolt))            
            EJ_library.assert.vector(bltsSamplesAVolt)
            assert(numel(bltsSamplesAVolt)==5)
            % Should ideally check for all indices, but one helps.
            assert(isnumeric(bltsSamplesAVolt{1}))
            
            % AS = "ASR Samples" (avolt)
%             NAN_VALUES = nan(size(bltsSamplesAVolt{1}));
%             As.dcV1  = NAN_VALUES;
%             As.dcV2  = NAN_VALUES;
%             As.dcV3  = NAN_VALUES;
%             As.dcV12 = NAN_VALUES;
%             As.dcV13 = NAN_VALUES;
%             As.dcV23 = NAN_VALUES;
%             As.acV12 = NAN_VALUES;
%             As.acV13 = NAN_VALUES;
%             As.acV23 = NAN_VALUES;
            As = struct();
            
            
            
            if dlrUsing12
                ROUTING_DC_V1x = bicas.proc.L1L2.demuxer.ROUTING_DC_V12;
                ROUTING_AC_V1x = bicas.proc.L1L2.demuxer.ROUTING_AC_V12;
            else
                ROUTING_DC_V1x = bicas.proc.L1L2.demuxer.ROUTING_DC_V13;
                ROUTING_AC_V1x = bicas.proc.L1L2.demuxer.ROUTING_AC_V13;
            end

            import bicas.proc.L1L2.demuxer.*

            % IMPLEMENTATION NOTE: BLTS 4 & 5 are routed independently of mux
            % mode, but the code hard-codes this separately for every case (i.e.
            % multiple times) for completeness.
            switch(demuxMode)
                
                case 0   % "Standard operation" : We have all information.
                    
                    % Summarize the routing.
                    RoutingArray(1) = bicas.proc.L1L2.demuxer.ROUTING_DC_V1;
                    RoutingArray(2) =                         ROUTING_DC_V1x;
                    RoutingArray(3) = bicas.proc.L1L2.demuxer.ROUTING_DC_V23;
                    RoutingArray(4) =                         ROUTING_AC_V1x;
                    RoutingArray(5) = bicas.proc.L1L2.demuxer.ROUTING_AC_V23;
                    %As = assign_ASR_samples_from_BLTS(As, bltsSamplesAVolt, RoutingArray);

                case 1   % Probe 1 fails

                    RoutingArray(1) = bicas.proc.L1L2.demuxer.ROUTING_DC_V2;
                    RoutingArray(2) = bicas.proc.L1L2.demuxer.ROUTING_DC_V3;
                    RoutingArray(3) = bicas.proc.L1L2.demuxer.ROUTING_DC_V23;
                    RoutingArray(4) =                         ROUTING_AC_V1x;
                    RoutingArray(5) = bicas.proc.L1L2.demuxer.ROUTING_AC_V23;
                    %As = assign_ASR_samples_from_BLTS(As, bltsSamplesAVolt, RoutingArray);
                    
                    % NOTE: Can not derive anything extra for DC. BLTS 1-3
                    % contain redundant data (regardless of latching relay
                    % setting).
                    
                case 2   % Probe 2 fails
                    
                    RoutingArray(1) = bicas.proc.L1L2.demuxer.ROUTING_DC_V1;
                    RoutingArray(2) = bicas.proc.L1L2.demuxer.ROUTING_DC_V3;
                    RoutingArray(3) =                         ROUTING_DC_V1x;
                    RoutingArray(4) = bicas.proc.L1L2.demuxer.ROUTING_AC_V13;
                    RoutingArray(5) = bicas.proc.L1L2.demuxer.ROUTING_AC_V23;
                    %As = assign_ASR_samples_from_BLTS(As, bltsSamplesAVolt, RoutingArray);
                    
                case 3   % Probe 3 fails

                    RoutingArray(1) = bicas.proc.L1L2.demuxer.ROUTING_DC_V1;
                    RoutingArray(2) = bicas.proc.L1L2.demuxer.ROUTING_DC_V2;
                    RoutingArray(3) =                         ROUTING_DC_V1x;
                    RoutingArray(4) =                         ROUTING_AC_V1x;
                    RoutingArray(5) = bicas.proc.L1L2.demuxer.ROUTING_AC_V23;
                    %As = assign_ASR_samples_from_BLTS(As, bltsSamplesAVolt, RoutingArray);

                case 4   % Calibration mode 0
                    
                    RoutingArray(1) = bicas.proc.L1L2.demuxer.ROUTING_DC_V1;
                    RoutingArray(2) = bicas.proc.L1L2.demuxer.ROUTING_DC_V2;
                    RoutingArray(3) = bicas.proc.L1L2.demuxer.ROUTING_DC_V3;
                    RoutingArray(4) =                         ROUTING_AC_V1x;
                    RoutingArray(5) = bicas.proc.L1L2.demuxer.ROUTING_AC_V23;
                    %As = assign_ASR_samples_from_BLTS(As, bltsSamplesAVolt, RoutingArray);

                case {5,6,7}   % Calibration mode 1/2/3

                    switch(demuxMode)
                        case 5
                            RoutingArray(1) = bicas.proc.L1L2.demuxer.ROUTING_25VREF_1_TO_DC_V1;
                            RoutingArray(2) = bicas.proc.L1L2.demuxer.ROUTING_25VREF_2_TO_DC_V2;
                            RoutingArray(3) = bicas.proc.L1L2.demuxer.ROUTING_25VREF_3_TO_DC_V3;
                        case {6,7}
                            RoutingArray(1) = bicas.proc.L1L2.demuxer.ROUTING_GND_1_TO_V1_LF;
                            RoutingArray(2) = bicas.proc.L1L2.demuxer.ROUTING_GND_2_TO_V2_LF;
                            RoutingArray(3) = bicas.proc.L1L2.demuxer.ROUTING_GND_3_TO_V3_LF;
                    end
                    RoutingArray(4) =                         ROUTING_AC_V1x;
                    RoutingArray(5) = bicas.proc.L1L2.demuxer.ROUTING_AC_V23;
                    %As = assign_ASR_samples_from_BLTS(As, bltsSamplesAVolt, RoutingArray);
                    
                otherwise
                    % IMPLEMENTATION NOTE: switch-case statement does not work
                    % for NaN. Therefore using "otherwise".
                    if isnan(demuxMode)
                        
                        % NOTE: The routing of BLTS 4 & 5 is identical for all
                        % mux modes (but does depend on the latching relay). Can
                        % therefore route them also when the mux mode is
                        % unknown.
                        RoutingArray(1) = bicas.proc.L1L2.demuxer.ROUTING_UNKNOWN_1_TO_NOTHING;
                        RoutingArray(2) = bicas.proc.L1L2.demuxer.ROUTING_UNKNOWN_2_TO_NOTHING;
                        RoutingArray(3) = bicas.proc.L1L2.demuxer.ROUTING_UNKNOWN_3_TO_NOTHING;
                        RoutingArray(4) =                         ROUTING_AC_V1x;
                        RoutingArray(5) = bicas.proc.L1L2.demuxer.ROUTING_AC_V23;
                        %As = assign_ASR_samples_from_BLTS(As, bltsSamplesAVolt, RoutingArray);
                        
                        % BUG/NOTE: Does not set any DC samples. Therefore just
                        % keeping the defaults. Can not derive any DC signals
                        % from other DC signals.
                        
                    else
                        error('BICAS:Assertion:IllegalArgument:DatasetFormat', ...
                            'Illegal argument value demuxMode=%g.', demuxMode)
                    end
            end    % switch
            
            As = assign_ASR_samples_from_BLTS(As, bltsSamplesAVolt, RoutingArray);
            As = complement_ASR(As);
            
            
            
            % ASSERTIONS
            EJ_library.assert.struct(As, bicas.proc.L1L2.demuxer.ASR_FIELDNAMES_CA, {})
            assert(numel(RoutingArray) == 5)
            assert(isstruct(RoutingArray))
            
            % Assign return values.
            BltsSrcArray    = [RoutingArray.src];
            AsrSamplesAVolt = As;
        end
        
        
        
        % Given an incomplete ASR struct, derive the missing ASRs using the
        % existing ones.
        %
        % NOTE: In the event of redundant FIELDS, but not redundant DATA
        % (non-fill value), the code can NOT make intelligent choice of only
        % using available data to replace fill values.
        %   Ex: mux=1: Fields (V1, V2, V12) but V1 does not contain any data
        %   (fill values). Could in principle derive V1=V2-V12 but code does
        %   not know this.
        %   NOTE: Unlikely that this will ever happen, or that the
        %   instrument RPW is even able to return data for this situation.
        %
        % NOTE: Only public for the purpose of automatic testing.
        %
        function AsrSamplesAVolt = complement_ASR(AsrSamplesAVolt)
            As = AsrSamplesAVolt;   % Shorten variable name.
            
            % NOTE: A relation can be complemented at most once, but algorithm
            % will try to complement relations multiple times.
            %
            % PROPOSAL: Add empty/NaN same-sized fields when can not derive any more fields. Assertion on fieldnames
            %           at the end.
            %
            % PROPOSAL: Implement on a record-by-record basis, with b indices to
            %           select which records should be derived.
            %   PRO: Can apply over multiple demultiplexer modes.
            %       CON: Not necessarily for non-antenna data. Might want to
            %       keep V12=NaN, but V1,V2=non-NaN for e.g. 2.5V ref data.
            %       Maybe...
            %   Ex: b1 = ~isnan(As.dcV1), ...
            %       b = b1 & b2 & ~b12;
            %       As.dcV12(b, :) = As.dcV1(b, :) - As.dcV2(b, :);
            
            N_ASR_FIELDNAMES = numel(bicas.proc.L1L2.demuxer.ASR_FIELDNAMES_CA);
            
            %================
            % Derive AC ASRs
            %================
            % AC ASRs are separate from DC. Does not have to be in loop.
            % IMPLEMENTATION NOTE: Must be executed before DC loop. Otherwise
            % nFnAfter == 9 condition does not work.
            As = bicas.proc.L1L2.demuxer.complete_relation(As, 'acV13', 'acV12', 'acV23');

            %================
            % Derive DC ASRs
            %================
            nFnBefore = numel(fieldnames(As));
            while true
                % NOTE: Relation dcV13 = dcV12 + dcV23 has precedence for
                % deriving diffs since it is better to derive a diff from
                % (initially available) diffs rather than singles, directly or
                % indirectly, if possible.
                As = bicas.proc.L1L2.demuxer.complete_relation(As, 'dcV13', 'dcV12', 'dcV23');
                
                As = bicas.proc.L1L2.demuxer.complete_relation(As, 'dcV1',  'dcV12', 'dcV2');
                As = bicas.proc.L1L2.demuxer.complete_relation(As, 'dcV1',  'dcV13', 'dcV3');
                As = bicas.proc.L1L2.demuxer.complete_relation(As, 'dcV2',  'dcV23', 'dcV3');
                nFnAfter = numel(fieldnames(As));
                
                if (nFnBefore == nFnAfter) || (nFnAfter == 9)
                    break
                end
                nFnBefore = nFnAfter;
            end
                        
            %===================================================================
            % Assign all ASRs/fields which have not yet been assigned
            % -------------------------------------------------------
            % IMPLEMENTATION NOTE: This is needed to handle for situations when
            % the supplied fields can not be used to determine all fields (five
            % fields are supplied but the system of equations is
            % overdetermined/redundant).
            %   Ex: mux=1,2,3
            %===================================================================
            tempNaN = nan(size(As.acV12));    % Use first field in fieldnames?
            for iFn = 1:N_ASR_FIELDNAMES
                fn = bicas.proc.L1L2.demuxer.ASR_FIELDNAMES_CA{iFn};
                if ~isfield(As, fn)
                    As.(fn) = tempNaN;
                end
            end
            
            EJ_library.assert.struct(As, bicas.proc.L1L2.demuxer.ASR_FIELDNAMES_CA, {})
            
            AsrSamplesAVolt = As;
        end
        
        
        
    end    % methods(Static, Access=public)
    
    
    
    %###########################################################################
    
    
    
    methods(Static, Access=private)
    %methods(Static, Access=public)
        
        
        % Utility function.
        % Create struct for a given BLTS describing where the physical signal
        % comes from and how it should be stored in the datasets. objects.
        %
        %
        % ARGUMENTS
        % =========
        % srcCategory, srcAntennas : Used to initialize .src
        %                            bicas.proc.L1L2.BLTS_src_dest.
        % varargin                 : 0 or 2 arguments.
        %                            Used to initialize .dest
        %                            bicas.proc.L1L2.BLTS_src_dest.
        %
        %
        % RETURN VALUE
        % ============
        % R : Struct. Fields are bicas.proc.L1L2.BLTS_src_dest.
        %   .src  : Where the physical signal in BLTS ultimately comes from.
        %           This is used to determine how the signal should be
        %           calibrated.
        %   .dest : How the BLTS should be stored in the datasets.
        %           If varargin is not used, then identical to .src .
        %
        function R = routing(srcCategory, srcAntennas, varargin)
            % PROPOSAL: Turn return value into class.
            
            R     = struct();
            R.src = bicas.proc.L1L2.BLTS_src_dest(srcCategory, srcAntennas);
            
            if numel(varargin) == 0
                R.dest = R.src;
            elseif numel(varargin) == 2
                R.dest = bicas.proc.L1L2.BLTS_src_dest(varargin{1}, varargin{2});
            else
                error('BICAS:Assertion:IllegalArgument', ...
                    'Illegal number of extra arguments.')
            end
        end
        
        
        
        % Overwrite ASR struct fields from all FIVE BLTS, given specified
        % routings. Does not touch other struct fields.
        function AsrSamples = assign_ASR_samples_from_BLTS(...
                AsrSamples, BltsSamplesAVolt, RoutingArray)
            
            % ASSERTIONS
            EJ_library.assert.all_equal(...
                [numel(BltsSamplesAVolt), numel(RoutingArray), 5])
            
            for iBlts = 1:5
                if ~strcmp(RoutingArray(iBlts).dest.category, 'Nowhere')
                    asrFn = bicas.proc.L1L2.demuxer.get_ASR_fieldname(...
                        RoutingArray(iBlts).dest);
                    AsrSamples.(asrFn) = BltsSamplesAVolt{iBlts};
                end
            end
        end
        
        
        
        % Convert a BLTS_src_dest (representing an ASR) to a corresponding
        % struct fieldname.
        function fn = get_ASR_fieldname(BltsDest)
            % PROPOSAL: New name implying "destination".
            
            BLTS_DEST_ASR_FN_TABLE = bicas.proc.L1L2.demuxer.BLTS_DEST_ASR_FN_TABLE;
            for i =1:size(BLTS_DEST_ASR_FN_TABLE, 1)
                if isequal(BltsDest, BLTS_DEST_ASR_FN_TABLE{i, 1})
                    fn = BLTS_DEST_ASR_FN_TABLE{i, 2};
                    return
                end
            end
            error('BICAS:Assertion:IllegalArgument', ...
                'Illegal argument BltsDest.')
        end
        
        
        
        % Utility function. Derive missing ASR fields from other fields. If
        % exactly two of the fieldnames exist in S, then derive the third using
        % the relationship As.(fn1) == As.(fn2) + As.(fn3)
        %
        % ARGUMENTS
        % =========
        % As             : Struct
        % fn1, fn2, fn3 : Existent or non-existent fieldnames in s.
        %
        function As = complete_relation(As, fn1, fn2, fn3)
            e1 = isfield(As, fn1);
            e2 = isfield(As, fn2);
            e3 = isfield(As, fn3);
            if     ~e1 &&  e2 &&  e3     As.(fn1) = As.(fn2) + As.(fn3);
            elseif  e1 && ~e2 &&  e3     As.(fn2) = As.(fn1) - As.(fn3);
            elseif  e1 &&  e2 && ~e3     As.(fn3) = As.(fn1) - As.(fn2);
            end
        end



    end    % methods(Static, Access=public)



end    % classdef
