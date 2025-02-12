%
% Collection of LFR-related processing functions.
%
%
% Author: Erik P G Johansson, Uppsala, Sweden
% First created 2021-05-25, from reorganized older code.
%
classdef lfr    
    % PROPOSAL: Automatic test code.

    
    
    %#######################
    %#######################
    % PUBLIC STATIC METHODS
    %#######################
    %#######################
    methods(Static)



        % Processing function. Only "normalizes" data to account for technically
        % illegal input LFR datasets. It should try to:
        % ** modify L1 to look like L1R
        % ** mitigate historical bugs in input datasets
        % ** mitigate for not yet implemented features in input datasets
        %
        function InSciNorm = process_normalize_CDF(InSci, inSciDsi, SETTINGS, L)

            % Default behaviour: Copy values, except for values which are
            % modified later
            InSciNorm = InSci;

            nRecords = EJ_library.assert.sizes(InSci.Zv.Epoch, [-1]);



            %===================================
            % Normalize CALIBRATION_TABLE_INDEX
            %===================================
            InSciNorm.Zv.CALIBRATION_TABLE_INDEX = ...
                bicas.proc.L1L2.normalize_CALIBRATION_TABLE_INDEX(...
                    InSci.Zv, nRecords, inSciDsi);



            %========================
            % Normalize SYNCHRO_FLAG
            %========================
            has_SYNCHRO_FLAG      = isfield(InSci.Zv, 'SYNCHRO_FLAG');
            has_TIME_SYNCHRO_FLAG = isfield(InSci.Zv, 'TIME_SYNCHRO_FLAG');
            if      has_SYNCHRO_FLAG && ~has_TIME_SYNCHRO_FLAG

                % CASE: Everything nominal.
                InSciNorm.Zv.SYNCHRO_FLAG = InSci.Zv.SYNCHRO_FLAG;

            elseif ~has_SYNCHRO_FLAG && has_TIME_SYNCHRO_FLAG

                % CASE: Input CDF uses wrong zVar name.
                [settingValue, settingKey] = ...
                    SETTINGS.get_fv('INPUT_CDF.USING_ZV_NAME_VARIANT_POLICY');
                bicas.default_anomaly_handling(L, ...
                    settingValue, settingKey, 'E+W+illegal', ...
                    'Found zVar TIME_SYNCHRO_FLAG instead of SYNCHRO_FLAG.')
                L.log('warning', ...
                    'Using illegally named zVar TIME_SYNCHRO_FLAG as SYNCHRO_FLAG.')
                InSciNorm.Zv.SYNCHRO_FLAG = InSci.Zv.TIME_SYNCHRO_FLAG;

            elseif has_SYNCHRO_FLAG && has_TIME_SYNCHRO_FLAG

                % CASE: Input CDF has two zVars: one with correct name, one with
                % incorrect name

                %------------------------
                % "Normal" normalization
                %------------------------
                % 2020-01-21: Based on skeletons (.skt; L1R, L2), SYNCHRO_FLAG
                % seems to be the correct zVar.
                if SETTINGS.get_fv(...
                        'INPUT_CDF.LFR.BOTH_SYNCHRO_FLAG_AND_TIME_SYNCHRO_FLAG_WORKAROUND_ENABLED') ...
                        && isempty(InSci.Zv.SYNCHRO_FLAG)
                    %----------------------------------------------------------
                    % Workaround: Normalize LFR data to handle variations that
                    % should not exist
                    %----------------------------------------------------------
                    % Handle that SYNCHRO_FLAG (empty) and TIME_SYNCHRO_FLAG
                    % (non-empty) may BOTH be present. "DEFINITION BUG" in
                    % definition of datasets/skeleton?
                    % Ex: LFR___TESTDATA_RGTS_LFR_CALBUT_V0.7.0/ROC-SGSE_L1R_RPW-LFR-SBM1-CWF-E_4129f0b_CNE_V02.cdf /2020-03-17

                    InSciNorm.Zv.SYNCHRO_FLAG = InSci.Zv.TIME_SYNCHRO_FLAG;
                else
                    error('BICAS:DatasetFormat', ...
                        ['Input dataset has both zVar SYNCHRO_FLAG and', ...
                        ' TIME_SYNCHRO_FLAG.'])
                end
            else
                error('BICAS:DatasetFormat', ...
                    'Input dataset does not have zVar SYNCHRO_FLAG as expected.')
            end



            %=======================================================================================================
            % Set QUALITY_BITMASK, QUALITY_FLAG:
            % Replace illegally empty data with fill values/NaN
            % ------------------------------------------------------------------
            % IMPLEMENTATION NOTE: QUALITY_BITMASK, QUALITY_FLAG have been found
            % empty in test data, but should have attribute DEPEND_0 = "Epoch"
            % ==> Should have same number of records as Epoch.
            %
            % Can not save CDF with zVar with zero records (crashes when reading
            % CDF). ==> Better create empty records.
            %
            % Examples of QUALITY_FLAG = empty:
            %  MYSTERIOUS_SIGNAL_1_2016-04-15_Run2__7729147__CNES/ROC-SGSE_L2R_RPW-LFR-SURV-SWF_7729147_CNE_V01.cdf
            %  ROC-SGSE_L1R_RPW-LFR-SBM1-CWF-E_4129f0b_CNE_V02.cdf (TESTDATA_RGTS_LFR_CALBUT_V1.1.0)
            %  ROC-SGSE_L1R_RPW-LFR-SBM2-CWF-E_6b05822_CNE_V02.cdf (TESTDATA_RGTS_LFR_CALBUT_V1.1.0)
            %=======================================================================================================
            % PROPOSAL: Move to the code that reads CDF datasets instead. Generalize to many zVariables.
            % PROPOSAL: Regard as "normalization" code. ==> Group together with other normalization code.
            %=======================================================================================================
            [settingValue, settingKey] = SETTINGS.get_fv(...
                'PROCESSING.L1R.LFR.ZV_QUALITY_FLAG_BITMASK_EMPTY_POLICY');

            InSciNorm.Zv.QUALITY_BITMASK = bicas.proc.L1L2.lfr.normalize_zVar_empty(...
                L, settingValue, settingKey, nRecords, ...
                InSci.Zv.QUALITY_BITMASK, 'QUALITY_BITMASK');

            InSciNorm.Zv.QUALITY_FLAG    = bicas.proc.L1L2.lfr.normalize_zVar_empty(...
                L, settingValue, settingKey, nRecords, ...
                InSci.Zv.QUALITY_FLAG,    'QUALITY_FLAG');

            % ASSERTIONS
            EJ_library.assert.sizes(...
                InSciNorm.Zv.QUALITY_BITMASK, [nRecords, 1], ...
                InSciNorm.Zv.QUALITY_FLAG,    [nRecords, 1])

        end    % process_normalize_CDF



        % Processing function. Convert LFR CDF data to PreDC.
        %
        % IMPLEMENTATION NOTE: Does not modify InSci in an attempt to save RAM
        % (should help MATLAB's optimization). Unclear if actually works.
        %
        function PreDc = process_CDF_to_PreDC(InSci, inSciDsi, HkSciTime, SETTINGS, L)
            %
            % PROBLEM: Hard-coded CDF data types (MATLAB classes).
            % MINOR PROBLEM: Still does not handle LFR zVar TYPE for determining
            % "virtual snapshot" length. Should only be relevant for
            % V01_ROC-SGSE_L2R_RPW-LFR-SURV-CWF (not V02) which should expire.

            % ASSERTIONS: VARIABLES
            assert(isa(InSci, 'bicas.InputDataset'))
            EJ_library.assert.struct(HkSciTime, {'MUX_SET', 'DIFF_GAIN'}, {})
            
            % ASSERTIONS: CDF
            assert(issorted(InSci.Zv.Epoch, 'strictascend'), ...
                'BICAS:DatasetFormat', ...
                ['Voltage (science) dataset timestamps Epoch do not', ...
                ' increase monotonously.'])
            nRecords = EJ_library.assert.sizes(InSci.Zv.Epoch, [-1]);



            C = bicas.classify_BICAS_L1_L1R_to_L2_DATASET_ID(inSciDsi);



            %============
            % Set iLsfZv
            %============
            if     C.isLfrSbm1   iLsfZv = ones(nRecords, 1) * 2;   % Always value "2" (F1, "FREQ = 1").
            elseif C.isLfrSbm2   iLsfZv = ones(nRecords, 1) * 3;   % Always value "3" (F2, "FREQ = 2").
            else                 iLsfZv = InSci.Zv.FREQ + 1;
                % NOTE: Translates from LFR's FREQ values (0=F0 etc) to LSF
                % index values (1=F0) used in loaded RCT data structs.
            end
            EJ_library.assert.sizes(iLsfZv, [nRecords])



            % NOTE: Needed also for 1 SPR.
            zvFreqHz = EJ_library.so.hwzv.get_LFR_frequency( iLsfZv );

            % Obtain the relevant values (one per record) from zVariables R0,
            % R1, R2, and the virtual "R3".
            zv_Rx = EJ_library.so.hwzv.get_LFR_Rx(...
                InSci.Zv.R0, ...
                InSci.Zv.R1, ...
                InSci.Zv.R2, ...
                iLsfZv );



            %===================================================================
            % IMPLEMENTATION NOTE: E & V must be floating-point so that values
            % can be set to NaN.
            %
            % Switch last two indices of E.
            % ==> index 2 = "snapshot" sample index, including for CWF
            %               (sample/record, "snapshots" consisting of 1 sample).
            %     index 3 = E1/E2 component
            %               NOTE: 1/2=index into array; these are diffs but not
            %               equivalent to any particular diffs).
            %===================================================================
            E = single(permute(InSci.Zv.E, [1,3,2]));

            % ASSERTIONS
            nCdfSamplesPerRecord = EJ_library.assert.sizes(...
                InSci.Zv.V, [nRecords, -1], ...
                E,          [nRecords, -1, 2]);
            if C.isLfrSurvSwf   assert(nCdfSamplesPerRecord == EJ_library.so.hwzv.const.LFR_SWF_SNAPSHOT_LENGTH)
            else                assert(nCdfSamplesPerRecord == 1)
            end



            PreDc = [];

            PreDc.Zv.samplesCaTm    = cell(5,1);
            PreDc.Zv.samplesCaTm{1} = single(InSci.Zv.V);
            % Copy values, except when zvRx==0 (==>NaN).
            PreDc.Zv.samplesCaTm{2} = bicas.proc.utils.filter_rows( E(:,:,1), zv_Rx==0 );
            PreDc.Zv.samplesCaTm{3} = bicas.proc.utils.filter_rows( E(:,:,2), zv_Rx==0 );
            PreDc.Zv.samplesCaTm{4} = bicas.proc.utils.filter_rows( E(:,:,1), zv_Rx==1 );
            PreDc.Zv.samplesCaTm{5} = bicas.proc.utils.filter_rows( E(:,:,2), zv_Rx==1 );

            PreDc.Zv.Epoch                   = InSci.Zv.Epoch;
            PreDc.Zv.DELTA_PLUS_MINUS        = bicas.proc.utils.derive_DELTA_PLUS_MINUS(...
                zvFreqHz, nCdfSamplesPerRecord);
            PreDc.Zv.freqHz                  = zvFreqHz;
            PreDc.Zv.nValidSamplesPerRecord  = ones(nRecords, 1) * nCdfSamplesPerRecord;
            PreDc.Zv.BW                      = InSci.Zv.BW;
            PreDc.Zv.useFillValues           = ~logical(InSci.Zv.BW);
            PreDc.Zv.DIFF_GAIN               = HkSciTime.DIFF_GAIN;
            PreDc.Zv.iLsf                    = iLsfZv;

            PreDc.Zv.SYNCHRO_FLAG            = InSci.Zv.SYNCHRO_FLAG;
            PreDc.Zv.CALIBRATION_TABLE_INDEX = InSci.Zv.CALIBRATION_TABLE_INDEX;

            PreDc.Zv.QUALITY_BITMASK         = InSci.Zv.QUALITY_BITMASK;
            PreDc.Zv.QUALITY_FLAG            = InSci.Zv.QUALITY_FLAG;



            %==========================================
            % Set MUX_SET
            % -----------
            % Select which source of mux mode is used.
            %==========================================
            [value, key] = SETTINGS.get_fv('PROCESSING.LFR.MUX_MODE_SOURCE');
            switch(value)
                case 'BIAS_HK'
                    L.log('debug', 'Using BIAS HK mux mode.')
                    MUX_SET = HkSciTime.MUX_SET;

                case 'LFR_SCI'
                    L.log('debug', 'Using LFR SCI mux mode.')
                    MUX_SET = InSci.Zv.BIAS_MODE_MUX_SET;

                case 'BIAS_HK_LFR_SCI'
                    L.log('debug', ...
                        ['Using mux mode from BIAS HK when available, and', ...
                        ' from LFR SCI when the former is not available.'])

                    % ASSERTION
                    % Added since the logic/algorithm is inherently relying on
                    % the implementation using NaN.
                    assert(isfloat(HkSciTime.MUX_SET))

                    MUX_SET              = HkSciTime.MUX_SET;
                    bUseBiasMux          = isnan(MUX_SET);
                    MUX_SET(bUseBiasMux) = InSci.Zv.BIAS_MODE_MUX_SET(bUseBiasMux);

                otherwise
                    error('BICAS:ConfigurationBug', ...
                        'Illegal settings value %s="%s"', key, value)
            end
            PreDc.Zv.MUX_SET = MUX_SET;



            PreDc.Ga.OBS_ID         = InSci.Ga.OBS_ID;
            PreDc.Ga.SOOP_TYPE      = InSci.Ga.SOOP_TYPE;

            PreDc.hasSnapshotFormat = C.isLfrSurvSwf;
            PreDc.isLfr             = true;
            PreDc.isTdsCwf          = false;



            % ASSERTIONS
            bicas.proc.L1L2.assert_PreDC(PreDc)

        end    % process_CDF_to_PreDC



        function [OutSci] = process_PostDC_to_CDF(SciPreDc, SciPostDc, outputDsi, L)
            % NOTE: Using __TDS__ function.
            OutSci = bicas.proc.L1L2.tds.process_PostDC_to_CDF(...
                SciPreDc, SciPostDc, outputDsi, L);

            OutSci.Zv.BW = SciPreDc.Zv.BW;
        end
        
        
        
    end    % methods(Static)
    
    
    
    %########################
    %########################
    % PRIVATE STATIC METHODS
    %########################
    %########################
    methods(Static, Access=private)



        % Local utility function to shorten & clarify code.
        %
        % ARGUMENTS
        % =========
        % zv1 : zVar-like variabel or empty. Column vector (Nx1) or empty.
        %
        % RETURN VALUE
        % ============
        % zv2 : If zv1 is non-empty, then zv2=zv1.
        %       If zv1 is empty,     then error/mitigate.
        %
        function zv2 = normalize_zVar_empty(...
                L, settingValue, settingKey, nRecords, zv1, zvName)

            if ~isempty(zv1)
                % Do nothing (except assertion later).
                zv2 = zv1;
            else
                anomalyDescrMsg = sprintf(...
                    'zVar "%s" from the LFR SCI source dataset is empty.', ...
                    zvName);
                switch(settingValue)
                    case 'USE_FILL_VALUE'
                        bicas.default_anomaly_handling(L, ...
                            settingValue, settingKey, 'other', ...
                            anomalyDescrMsg, ...
                            'BICAS:DatasetFormat:SWModeProcessing')

                        L.logf('warning', 'Using fill values for %s.', zvName)
                        zv2 = nan(nRecords, 1);

                    otherwise
                        bicas.default_anomaly_handling(L, ...
                            settingValue, settingKey, 'E+illegal', ...
                            anomalyDescrMsg, ...
                            'BICAS:DatasetFormat:SWModeProcessing')
                end
            end

            EJ_library.assert.sizes(zv2, [NaN])
        end
        
        
        
    end    % methods(Static, Access=private)

end
