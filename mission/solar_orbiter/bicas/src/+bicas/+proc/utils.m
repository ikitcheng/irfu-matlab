%
% Collection of minor utility functions (in the form of static methods) used for
% data processing.
%
%
% TERMINOLOGY
% ===========
% SPR = Samples Per (CDF-like) Record
%
%
% Author: Erik P G Johansson, IRF, Uppsala, Sweden
% First created 2016-10-10
%
classdef utils
%
% PROPOSAL: POLICY: No functions which set "policy"/configure the output of
%           datasets.
%
% PROPOSAL: Split up in separate files?!
%   PROPOSAL: Move all functions that are used outside bicas.proc to
%             "bicas.utils" (class). -- DONE
%   PROPOSAL: Move functions that are entirely used within a group/package of processing modes
%           (L1L2, L2L2, L2L3) to their respective group.
%       Ex: L1L2
%           Ex: lfr.m, dts.m: derive_DELTA_PLUS_MINUS
%           Ex: lfr.m:        bicas.proc.utils.filter_rows
%           Ex: tds.m:        set_NaN_after_snapshots_end
%           Ex: dc.m:
%                   select_row_range_from_cell_comps
%                   assert_cell_array_comps_have_same_N_rows (used by select_row_range_from_cell_comps)
%                   convert_matrix_to_cell_array_of_vectors
%           Ex: L1L2.m:       ACQUISITION_TIME_to_TT2000
%                             (not used in processing function directly, only indirectly)
%       CON: Useful to have all SMALL functions collected.
%       CON: Can forget that a function exists if it is needed somewhere else.
%       TODO-DEC: Move to subfile if only used there instead?
%           Ex: Move function to lfr.m instead of L1L2.m?
%
% PROPOSAL: Write test code for ACQUISITION_TIME_to_TT2000 and its inversion.
%
% N-->1 sample/record
%    NOTE: Time conversion may require moving the zero-point within the snapshot/record.
%    PROPOSAL: : All have nSamplesPerOldRecord as column vector.
%       PRO: LFR.
%    PROPOSAL: First convert column data to 2D data (with separate functions),
%              then reshape to 1D with one common function.
%       CON: Does not work for ACQUISITION_TIME since two columns.



    methods(Static, Access=public)
        
        
        
        % Wrapper around bicas.handle_struct_name_change() to be used
        % locally.
        %
        % ARGUMENTS
        % =========
        % inSciDsi : Input SCI DATASET_ID which contains the zVariable.
        % varargin : Passed on to bicas.handle_struct_name_change as its
        %            varargin.
        %
        function handle_zv_name_change(fnChangeList, inSciDsi, SETTINGS, L, varargin)
            anomalyDescrMsgFunc = @(oldFieldname, newFieldname) (sprintf(...
                ['Input dataset DATASET_ID=%s uses an alternative', ...
                ' but illegal(?) zVariable name "%s" instead of "%s".'], ...
                inSciDsi, oldFieldname, newFieldname));

            bicas.handle_struct_name_change(...
                fnChangeList, ...
                SETTINGS, L, anomalyDescrMsgFunc, varargin{:})
        end



        function c2 = select_row_range_from_cell_comps(c1, iFirst, iLast)
        % For every cell in a cell array, select an index range in the first
        % dimension for every cell array component.
            
            % ASSERTIONS
            bicas.proc.utils.assert_cell_array_comps_have_same_N_rows(c1)
            
            for i = 1:numel(c1)
                c2{i} = c1{i}(iFirst:iLast, :, :,:,:,:);
            end
        end



        function S = set_struct_field_rows(S, SNew, iRowsArray)
        % Generic utility function.
        % Overwrite struct fields at specific field rows using other struct
        % fields.
        %
        %
        % ARGUMENTS
        % =========
        % S
        %       Struct. Only numeric fields.
        %       All fields have same number of rows.
        % SNew
        %       Struct. Only numeric fields. 
        %       All fields have same number of rows. Same fields as S.
        % iRowsArray
        %       1D array. Same length as number of rows in SNew fields.
        %       Specifies the rows (in fields in S) that shall be assigned.

            % ASSERTIONS
            bicas.proc.utils.assert_struct_num_fields_have_same_N_rows(S);
            nRowsSa = bicas.proc.utils.assert_struct_num_fields_have_same_N_rows(SNew);
            assert(numel(iRowsArray) == nRowsSa)
            EJ_library.assert.castring_sets_equal(fieldnames(S), fieldnames(SNew))
            
            fieldNamesList = fieldnames(SNew);
            for i=1:length(fieldNamesList)
                fn = fieldNamesList{i};
                
                % ASSERTIONS
                assert(isnumeric(S.(fn)))
                assert(isnumeric(SNew.(fn)))
                
                S.(fn)(iRowsArray, :) = SNew.(fn)(:, :);
            end
        end
        


        % Convert 2D array --> 1D cell array of 1D arrays, one per source row.
        %
        %
        % ARGUMENTS
        % =========
        % M                    : 2D matrix
        % nCopyColsPerRowArray : 1D column vector. Numeric.
        %                        {i}=Number of elements to copy from M{i,:}.
        %
        % RETURN VALUE
        % ============
        % ca                   : Column cell array of 1D vectors.
        %
        function ca = convert_matrix_to_cell_array_of_vectors(M, nCopyColsPerRowArray)
            
            % ASSERTIONS
            EJ_library.assert.vector(nCopyColsPerRowArray)
            nRows = EJ_library.assert.sizes(...
                M,                    [-1, NaN], ...
                nCopyColsPerRowArray, [-1, 1]);
            
            
            
            ca = cell(size(M, 1), 1);
            for iRow = 1:nRows
                ca{iRow} = M(iRow, 1:nCopyColsPerRowArray(iRow));
            end
        end
        

        
        % ARGUMENTS
        % =========
        % ca                 : Column cell array of 1D vectors.
        % nMatrixColumns     : Scalar. Number of columns in M.
        % M                  : Numeric 2D matrix.
        %                      NOTE: Sets unset elements to NaN.
        % nCopyColsPerRowVec : 1D vector. {i}=Length of ca{i}=Number of
        %                      elements copyied to M{i,:}.
        function [M, nCopyColsPerRowVec] = ...
                convert_cell_array_of_vectors_to_matrix(ca, nMatrixColumns)
            assert(iscell(ca))
            EJ_library.assert.vector(ca)
            assert(isscalar(nMatrixColumns))
            EJ_library.assert.vector(nMatrixColumns)
            
            nCopyColsPerRowVec = zeros(numel(ca), 1);   % Always column vector.
            M                  = nan(  numel(ca), nMatrixColumns);
            for iRow = 1:numel(nCopyColsPerRowVec)
                nCopyColsPerRowVec(iRow)            = numel(ca{iRow});
                M(iRow, 1:nCopyColsPerRowVec(iRow)) = ca{iRow};
            end
            
        end

        
        
        %################################
        % MODIFYING, DERIVING ZVARIABLES
        %################################
        
        
        
        function zvData = filter_rows(zvData, bRowFilter)
        % Function intended for filtering out data from a zVariable by setting
        % parts of it to NaN. Also useful for constructing aonymous functions.
        %
        %
        % ARGUMENTS
        % =========
        % data         : Numeric array with N rows.                 
        % bRowFilter   : Numeric/logical column vector with N rows.
        %
        %
        % RETURN VALUE
        % ============
        % filteredData :
        %         Array of the same size as "data", such that
        %         filteredData(i,:,:) == NaN,         for rowFilter(i)==0.
        %         filteredData(i,:,:) == data(i,:,:), for rowFilter(i)~=0.
        
        % PROPOSAL: Better name? ~set_records_NaN

            % ASSERTIONS
            % Mostly to make sure the caller knows that it represents true/false.
            assert(islogical(bRowFilter))
            assert(isfloat(zvData), ...
                'BICAS:Assertion:IllegalArgument', ...
                ['Argument "data" is not a floating-point class (can', ...
                ' therefore not represent NaN).'])
            % Not really necessary to require row vector, only 1D vector.
            EJ_library.assert.sizes(...
                zvData,     [-1, NaN, NaN], ...
                bRowFilter, [-1])


            
            % Overwrite data with NaN
            % -----------------------
            % IMPLEMENTATION NOTE: Command works empirically for filteredData
            % having any number of dimensions. However, if rowFilter and
            % filteredData have different numbers of rows, then the final array
            % may get the wrong dimensions (without triggering error!) since new
            % array components (indices) are assigned. ==> Having a
            % corresponding ASSERTION is important!
            zvData(bRowFilter, :) = NaN;
        end

        
        
        function zv = set_NaN_after_snapshots_end(zv, snapshotLengths)
            % ASSERTIONS
            [nRecords, snapshotMaxLength] = EJ_library.assert.sizes(...
                zv,              [-1, -2], ...
                snapshotLengths, [-1]);
            assert(snapshotMaxLength >= max([snapshotLengths; 0]))
            % Add zero to vector so that max gives sensible value for empty
            % snapshotLengths.
                        
            % IMPLEMENTATION
            for iRecord = 1:nRecords
                zv(iRecord, (snapshotLengths(iRecord)+1):end) = NaN;
            end
        end


        
        function tt2000 = ACQUISITION_TIME_to_TT2000(...
                ACQUISITION_TIME, ACQUISITION_TIME_EPOCH_UTC)
        %
        % Convert time in from ACQUISITION_TIME to tt2000 which is used for
        % Epoch in CDF files.
        % 
        % 
        % ARGUMENTS
        % =========
        % ACQUSITION_TIME            : NOTE: Can be negative since it is uint32.
        % ACQUISITION_TIME_EPOCH_UTC :
        %               Numeric row vector. The time in UTC at
        %               which ACQUISITION_TIME == [0,0], expressed as
        %               [year, month, day, hour, minute, second, 
        %                millisecond, microsecond(0-999), nanoseconds(0-999)].
        %
        %
        % RETURN VALUE
        % ============
        % tt2000 : NOTE: int64
        %
        
            bicas.utils.assert_zv_ACQUISITION_TIME(ACQUISITION_TIME)
            
            % at = ACQUISITION_TIME
            ACQUISITION_TIME = double(ACQUISITION_TIME);
            atSeconds = ACQUISITION_TIME(:, 1) + ACQUISITION_TIME(:, 2) / 65536;
            % NOTE: spdfcomputett2000 returns int64 (as it should).
            tt2000 = spdfcomputett2000(ACQUISITION_TIME_EPOCH_UTC) ...
                + int64(atSeconds * 1e9);
        end
        

        
        function ACQUISITION_TIME = TT2000_to_ACQUISITION_TIME(...
                tt2000, ACQUISITION_TIME_EPOCH_UTC)
        %
        % Convert from tt2000 to ACQUISITION_TIME.
        %
        % ARGUMENTS
        % =========
        % t_tt2000
        %       Nx1 vector. Required to be int64 like the real zVar Epoch.
        %
        % RETURN VALUE
        % ============
        % ACQUISITION_TIME : Nx2 vector. uint32.
        %       NOTE: ACQUSITION_TIME can not be negative since it is uint32.
        %
        
            % ASSERTIONS
            bicas.utils.assert_zv_Epoch(tt2000)

            % NOTE: Important to type cast to double because of multiplication
            % AT = ACQUISITION_TIME
            atSeconds = double(int64(tt2000) - ...
                spdfcomputett2000(ACQUISITION_TIME_EPOCH_UTC)) * 1e-9;
            
            % ASSERTION: ACQUISITION_TIME must not be negative.
            if any(atSeconds < 0)
                error(...
                    'BICAS:Assertion:IllegalArgument:DatasetFormat', ...
                    ['Can not produce ACQUISITION_TIME (uint32) with', ...
                    ' negative number of integer seconds.'])
            end
            
            atSeconds = round(atSeconds*65536) / 65536;
            atSecondsFloor = floor(atSeconds);
            
            ACQUISITION_TIME = uint32([]);
            ACQUISITION_TIME(:, 1) = uint32(atSecondsFloor);
            ACQUISITION_TIME(:, 2) = uint32((atSeconds - atSecondsFloor) * 65536);
            % NOTE: Should not be able to produce ACQUISITION_TIME(:, 2)==65536
            % (2^16) since atSeconds already rounded (to parts of 2^-16).
        end



        function zv_DELTA_PLUS_MINUS = derive_DELTA_PLUS_MINUS(freqHz, nSpr)
        %
        % Derive value for zVar DELTA_PLUS_MINUS.
        %
        % NOTE: All values on any given row (CDF record) of DELTA_PLUS_MINUS are
        % identical. Not sure why multiple values per row are needed but it is
        % probably intentional, as per YK's instruction.
        %
        %
        % ARGUMENTS
        % =========
        % freqHz : Frequency column vector in s^-1.
        %          Can not handle freqHz=NaN since the output is an
        %          integer (assertion).
        % nSpr   : Number of samples/record.
        %
        % 
        % RETURN VALUE
        % ============
        % DELTA_PLUS_MINUS : Analogous to BIAS zVariable. CDF_INT8=int64.
        %                    NOTE: Unit ns.
        %
        
            ZV_DELTA_PLUS_MINUS_DATA_TYPE = 'CDF_INT8';
            
            % ASSERTIONS
            nRecords = EJ_library.assert.sizes(freqHz, [-1]);
            assert(isfloat(freqHz) && all(isfinite(freqHz)), ...
                'BICAS:Assertion:IllegalArgument', ...
                'Argument "freqHz" does not consist of non-NaN floats.')
            assert(isscalar(nSpr), ...
                'BICAS:Assertion:IllegalArgument', ...
                'Argument "nSpr" is not a scalar.')
            
            
            
            zv_DELTA_PLUS_MINUS = zeros([nRecords, nSpr]);
            %DELTA_PLUS_MINUS = zeros([nRecords, 1]);    % Always 1 sample/record.
            for i = 1:nRecords
                % NOTE: Converts [s] (1/freqHz) --> [ns] (DELTA_PLUS_MINUS) so
                % that the unit is the same as for Epoch.
                % NOTE: Seems to work for more than 2D.
                % Unit: nanoseconds
                zv_DELTA_PLUS_MINUS(i, :) = 1./freqHz(i) * 1e9 * 0.5;
            end
            zv_DELTA_PLUS_MINUS = cast(zv_DELTA_PLUS_MINUS, ...
                EJ_library.cdf.convert_CDF_type_to_MATLAB_class(...
                    ZV_DELTA_PLUS_MINUS_DATA_TYPE, 'Only CDF data types'));
        end
        
        
        
        %############
        % ASSERTIONS
        %############
        
        
        
        function nRows = assert_struct_num_fields_have_same_N_rows(S)
        % Assert that data structure have the same number of rows in its
        % constituent parts.
        %
        % Useful for structs where all fields represent CDF zVariables and/or
        % derivatives thereof, the size in the first index (number of CDF
        % record) should be equal.
        %
        %
        % ARGUMENTS
        % =========
        % S : Struct
        %       Fields may (ony) be of the following types. Number of rows must
        %       be identical for the specified data structure components
        %       (right-hand side).
        %       (1) numeric/logical fields  : The field itself.
        %       (2) cell fields             : Cell array components (not
        %                                     the cell array itself!).
        %       (3) struct field (in struct): The inner struct's fields (not
        %                                     recursive).
        %
        %
        % ACTUAL USAGE OF SPECIAL CASES FOR FIELDS (non-array fields)
        % ===========================================================
        % PreDc.Zv.samplesCaTm    : Cell array of cell arrays.
        % PostDc.Zv.DemuxerOutput : Struct of arrays.
        %

        % NOTE: Function name somewhat bad.
        % PROPOSAL: Make recursive?!
        % PROPOSAL: Implement using new features in EJ_library.assert.sizes().
        
            fieldNamesList1 = fieldnames(S);
            nRowsArray = [];
            for iFn1 = 1:length(fieldNamesList1)
                fieldValue = S.(fieldNamesList1{iFn1});
                
                if isnumeric(fieldValue) || islogical(fieldValue)
                    
                    nRowsArray(end+1) = size(fieldValue, 1);
                    
                elseif iscell(fieldValue)
                    
                    for iCc = 1:numel(fieldValue)
                        nRowsArray(end+1) = size(fieldValue{iCc}, 1);
                    end
                    
                elseif isstruct(fieldValue)
                    
                    fieldNamesList2 = fieldnames(fieldValue);
                    for iFn2 = 1:length(fieldNamesList2)
                        nRowsArray(end+1) = size(...
                            fieldValue.(fieldNamesList2{iFn2}), ...
                            1);
                    end
                    
                else
                    
                    error('BICAS:Assertion', ...
                        'Can not handle this type of struct field.')
                    
                end
            end
            
            % NOTE: Empty vector if nRowsArray is empty.
            nRows = unique(nRowsArray);   
            
            % NOTE: length==0 valid for struct containing zero numeric fields.
            if length(unique(nRowsArray)) > 1    
                error('BICAS:Assertion', ...
                    ['Numeric fields and cell array components', ...
                    ' in struct do not have the same number', ...
                    ' of rows (likely corresponding to CDF zVar records).'])
            end
        end
        
        
        
        % Assert that all cell array components have the same number of rows.
        % This is useful when cell array components represent zVar-like data,
        % where rows represent CDF records.
        %
        % ARGUMENTS
        % =========
        % ca : Cell array
        %
        function assert_cell_array_comps_have_same_N_rows(ca)
            nRowsArray = cellfun(@(v) (size(v,1)), ca, 'UniformOutput', true);
            EJ_library.assert.all_equal( nRowsArray )
        end



    end   % Static
    
    
    
end
