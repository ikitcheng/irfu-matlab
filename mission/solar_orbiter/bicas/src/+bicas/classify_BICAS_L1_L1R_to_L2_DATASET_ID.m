%
% Classify DATASET_ID for any BICAS L1/L1R-->L2 input/output dataset.
%
%
% ARGUMENTS
% =========
% datasetId
%       DATASET_ID for any BICAS processing L1/L1R-->L2 datasets.
%       Assertion error if other DATASET_ID.
%       NOTE: Excludes CURRENT, SWEEP, HK, L3 datasets.
%
%
% RETURN VALUES
% =============
% C
%       Struct with fields for relevant flags.
%
%
% Author: Erik P G Johansson, Uppsala, Sweden
% First created 2020-09-29.
%
function C = classify_BICAS_L1_L1R_to_L2_DATASET_ID(datasetId)
    % PROPOSAL: Automatic test code.
    
    [~, datasetLevel, descriptor] = ...
        EJ_library.so.adm.disassemble_DATASET_ID(datasetId);
    
    C.isL1  = false;
    C.isL1r = false;
    C.isL2  = false;
    % One flag per type of input/output voltage data.
    % IMPLEMENTATION NOTE: Avoiding the flag name isLfrCwf since it is
    % ambiguous. isLfrSurvSwf is chosen in analogy with isLfrSurvCwf.
    C.isLfrSbm1    = false;
    C.isLfrSbm2    = false;
    C.isLfrSurvCwf = false;
    C.isLfrSurvSwf = false;
    C.isTdsCwf     = false;
    C.isTdsRswf    = false;
    
    switch(datasetLevel)
        case 'L1'
            C.isL1 = true;
            descriptorNormalized = descriptor;
            
        case 'L1R'
            C.isL1r = true;
            descriptorNormalized = descriptor(1:end-2);

        case 'L2'
            C.isL2 = true;
            descriptorNormalized = descriptor(1:end-2);
            
        otherwise
            error(...
                'datasetId="%s" is not a legal BICAS L1/L1R input DATASET_ID.', ...
                datasetId)
    end
    
    switch(descriptorNormalized)
        case 'RPW-LFR-SBM1-CWF' ; C.isLfrSbm1    = true;
        case 'RPW-LFR-SBM2-CWF' ; C.isLfrSbm2    = true;
        case 'RPW-LFR-SURV-CWF' ; C.isLfrSurvCwf = true;
        case 'RPW-LFR-SURV-SWF' ; C.isLfrSurvSwf = true;
        case 'RPW-TDS-LFM-CWF'  ; C.isTdsCwf     = true;
        case 'RPW-TDS-LFM-RSWF' ; C.isTdsRswf    = true;
        otherwise
            error(...
                'datasetId="%s" is not a legal BICAS L1/L1R input DATASET_ID.', ...
                datasetId)
    end
    
    %================================================
    % Set flags that can be derived from other flags
    %================================================
    C.isLfr = C.isLfrSbm1 | C.isLfrSbm2 | C.isLfrSurvCwf | C.isLfrSurvSwf;
    C.isTds = C.isTdsCwf  | C.isTdsRswf;
    C.isCwf = C.isLfrSbm1 | C.isLfrSbm2 | C.isLfrSurvCwf | C.isTdsCwf;
    C.isSwf = C.isLfrSurvSwf                             | C.isTdsRswf;
    
end
