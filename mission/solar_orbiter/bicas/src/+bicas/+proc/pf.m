%
% Set of functions which are almost "production functions" (PF), i.e. almost
% functions for producing one specific output dataset PDV from the necessary
% input dataset PDVs. The functions here can easily be used to create anonymous
% functions which adhere to the interface required to be a "production function"
% (below).
%
%
% DEFINITION: PRODUCTION FUNCTION
% ===============================
% A function with interface
%   OutputsMap = produce_*(InputsMap, rctDir, NsoTable)
% with arguments and return values:
% InputsMap
%       containers.Map with
%       <keys>   : String defining a name of an input ("prodFuncInputKey" in
%                  swmode_defs).
%       <values> : A struct with data corresponding to a CDF file
%                  (zVariables+global attributes).
% OutputsMap
%       containers.Map with
%       <keys>   : String defining a name of an output ("prodFuncOutputKey" in
%                  swmode_defs).
%       <values> : A struct with data corresponding to a CDF file (zVariables).
% --
% NOTE: In practice, anonymous functions with the correct interface are used to
% wrap the actual implementing functions (with another interface).
% --
% Production functions should not assume/specify any particular
% input dataset version, but read it out from global attributes (part of the
% PDV).
%
%
% Author: Erik P G Johansson, IRF, Uppsala, Sweden
% First created 2019-07-30
%
classdef pf

    % PROPOSAL: Function for constructing RctDataMap.
    % PROPOSAL: Merge functions produce_L1R_to_L2_LFR/TDS().
    
    
    
    methods(Static, Access=public)
        
        
        
        % ARGUMENTS
        % =========
        % inputSciDsi
        %       The science input dataset will be interpreted as having this
        %       DATASET_ID.
        %       RATIONALE: InputDatasetsMap should contain the same as a CDF
        %       global attribute but
        %       (1) it could be missing, or
        %       (2) sometimes one may want to read an ROC-SGSE dataset as if it
        %           was an RODP dataset or the other way around.
        %
        function [OutputDatasetsMap] = produce_L1R_to_L2_LFR(...
                InputDatasetsMap, rctDir, NsoTable, inputSciDsi, outputDsi, ...
                SETTINGS, L)
            
            InputHkCdf  = InputDatasetsMap('HK_cdf');
            InputCurCdf = InputDatasetsMap('CUR_cdf');
            InputSciCdf = InputDatasetsMap('SCI_cdf');

            
            
            %======================================
            % Configure bicas.proc.L1L2.cal object
            %======================================
            C = bicas.classify_BICAS_L1_L1R_to_L2_DATASET_ID(inputSciDsi);
            useCtRcts = C.isL1r && SETTINGS.get_fv('PROCESSING.L1R.LFR.USE_GA_CALIBRATION_TABLE_RCTS');
            useCti2   = C.isL1r && SETTINGS.get_fv('PROCESSING.L1R.LFR.USE_ZV_CALIBRATION_TABLE_INDEX2');
            
            if useCtRcts
                RctDataMap = bicas.proc.L1L2.cal_RCT.find_read_RCTs_by_regexp_and_CALIBRATION_TABLE(...
                    'LFR', rctDir, ...
                    InputSciCdf.Ga.CALIBRATION_TABLE, ...
                    InputSciCdf.Zv.CALIBRATION_TABLE_INDEX, ...
                    InputSciCdf.Zv.BW, ...
                    SETTINGS, L);
            else
                RctDataMap = bicas.proc.L1L2.cal_RCT.find_read_RCTs_by_regexp(...
                    {'BIAS', 'LFR'}, rctDir, SETTINGS, L);
            end
            
            Cal = bicas.proc.L1L2.cal(RctDataMap, useCtRcts, useCti2, SETTINGS);
            
            
            
            %==============
            % Process data
            %==============
            HkSciTimePd           = bicas.proc.L1L2.process_HK_CDF_to_HK_on_SCI_TIME(InputSciCdf, InputHkCdf,  SETTINGS, L);
            InputSciCdf           = bicas.proc.L1L2.lfr.process_normalize_CDF(       InputSciCdf, inputSciDsi, SETTINGS, L);
            SciPreDc              = bicas.proc.L1L2.lfr.process_CDF_to_PreDC(        InputSciCdf, inputSciDsi, HkSciTimePd, SETTINGS, L);
            SciPostDc             = bicas.proc.L1L2.dc.process_calibrate_demux(      SciPreDc, InputCurCdf, Cal,    SETTINGS, L);
            [SciPreDc, SciPostDc] = bicas.proc.L1L2.process_quality_filter_L2(       SciPreDc, SciPostDc, NsoTable, SETTINGS, L);
            OutputSciCdf          = bicas.proc.L1L2.lfr.process_PostDC_to_CDF(       SciPreDc, SciPostDc, outputDsi, L);
            
            
            
            OutputDatasetsMap = containers.Map();
            OutputDatasetsMap('SCI_cdf') = OutputSciCdf;
        end



        function [OutputDatasetsMap] = produce_L1R_to_L2_TDS(...
                InputDatasetsMap, rctDir, NsoTable, inputSciDsi, outputDsi, ...
                SETTINGS, L)
            
            InputHkCdf  = InputDatasetsMap('HK_cdf');
            InputCurCdf = InputDatasetsMap('CUR_cdf');
            InputSciCdf = InputDatasetsMap('SCI_cdf');
            
            
            
            %======================================
            % Configure bicas.proc.L1L2.cal object
            %======================================
            % NOTE: TDS L1R never uses CALIBRATION_TABLE_INDEX2
            C = bicas.classify_BICAS_L1_L1R_to_L2_DATASET_ID(inputSciDsi);
            if C.isTdsCwf
                settingUseCt = 'PROCESSING.L1R.TDS.CWF.USE_GA_CALIBRATION_TABLE_RCTS';
                tdsRctTypeId = 'TDS-CWF';
            else
                settingUseCt = 'PROCESSING.L1R.TDS.RSWF.USE_GA_CALIBRATION_TABLE_RCTS';
                tdsRctTypeId = 'TDS-RSWF';
            end
            useCtRcts = C.isL1r && SETTINGS.get_fv(settingUseCt);
            useCti2   = false;    % Always false for TDS.
            
            if useCtRcts
                % Create fake zv_BW since it does not exist for TDS (only LFR).
                % NOTE: This should not be regarded as a hack but as
                % ~normalization to avoid later special cases.
                zv_BW = uint8(ones(...
                    size(InputSciCdf.Zv.CALIBRATION_TABLE_INDEX, 1), ...
                    1));
                
                RctDataMap = bicas.proc.L1L2.cal_RCT.find_read_RCTs_by_regexp_and_CALIBRATION_TABLE(...
                    tdsRctTypeId, rctDir, ...
                    InputSciCdf.Ga.CALIBRATION_TABLE, ...
                    InputSciCdf.Zv.CALIBRATION_TABLE_INDEX, ...
                    zv_BW, ...
                    SETTINGS, L);
            else
                RctDataMap = bicas.proc.L1L2.cal_RCT.find_read_RCTs_by_regexp(...
                    {'BIAS', tdsRctTypeId}, rctDir, SETTINGS, L);
            end
            
            Cal = bicas.proc.L1L2.cal(RctDataMap, useCtRcts, useCti2, SETTINGS);
            
            
            
            %==============
            % Process data
            %==============
            HkSciTimePd           = bicas.proc.L1L2.process_HK_CDF_to_HK_on_SCI_TIME(InputSciCdf, InputHkCdf,  SETTINGS, L);
            InputSciCdf           = bicas.proc.L1L2.tds.process_normalize_CDF(       InputSciCdf, inputSciDsi, SETTINGS, L);
            SciPreDc              = bicas.proc.L1L2.tds.process_CDF_to_PreDC(        InputSciCdf, inputSciDsi, HkSciTimePd, SETTINGS, L);
            SciPostDc             = bicas.proc.L1L2.dc.process_calibrate_demux(      SciPreDc, InputCurCdf, Cal, SETTINGS, L);
            [SciPreDc, SciPostDc] = bicas.proc.L1L2.process_quality_filter_L2(       SciPreDc, SciPostDc, NsoTable, SETTINGS, L);
            OutputSciCdf          = bicas.proc.L1L2.tds.process_PostDC_to_CDF(       SciPreDc, SciPostDc, outputDsi, L);

            
            
            OutputDatasetsMap = containers.Map();
            OutputDatasetsMap('SCI_cdf') = OutputSciCdf;
        end
        
        
        
        function [OutputDatasetsMap] = produce_L2_to_L2_CWF_DWNS(...
                InputDatasetsMap, ...
                SETTINGS, L)
            
            InLfrCwf = InputDatasetsMap('ORIS_cdf');
            
            OutLfrCwfDwns = bicas.proc.L2L2.process_LFRCWF_to_DWNS(InLfrCwf, SETTINGS, L);
            
            OutputDatasetsMap = containers.Map();
            OutputDatasetsMap('DWNS_cdf') = OutLfrCwfDwns;
        end
        
        
        
        function [OutputDatasetsMap] = produce_L2_to_L3(...
                InputDatasetsMap, ...
                SETTINGS, L)
            
            InputLfrCwfCdf = InputDatasetsMap('LFR-SURV-CWF-E_cdf');

            %==============
            % Process data
            %==============
            [EfieldOrisCdf,  EfieldDwnsCdf, ...
             ScpotOrisCdf,   ScpotDwnsCdf, ...
             DensityOrisCdf, DensityDwnsCdf] = ...
                bicas.proc.L2L3.process_L2_to_L3(InputLfrCwfCdf, SETTINGS, L);

            OutputDatasetsMap = containers.Map();
            OutputDatasetsMap('EFIELD_ORIS_cdf')  = EfieldOrisCdf;
            OutputDatasetsMap('EFIELD_DWNS_cdf')  = EfieldDwnsCdf;
            OutputDatasetsMap('SCPOT_ORIS_cdf')   = ScpotOrisCdf;
            OutputDatasetsMap('SCPOT_DWNS_cdf')   = ScpotDwnsCdf;
            OutputDatasetsMap('DENSITY_ORIS_cdf') = DensityOrisCdf;
            OutputDatasetsMap('DENSITY_DWNS_cdf') = DensityDwnsCdf;
        end
        
        
        
    end    % methods(Static, Access=public)
    
    
    
end    % classdef
