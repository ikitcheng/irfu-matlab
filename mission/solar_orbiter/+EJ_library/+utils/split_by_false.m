%
% Given a boolean array, find uninterrupted sequences of true.
%
%
% ARGUMENTS
% =========
% boolArray
%       1D array. Boolean or numeric.
%
%
% RETURN VALUES
% =============
% i1Array, i2Array
%       Nx1 arrays, numeric, same size. Indices such that
%       boolArray(i1Array(i) : i2Array(i)) == true,
%       and covers all true values in boolArray exactly once.
%
%
% Author: Erik P G Johansson, Uppsala, Sweden
% First created 2020-05-26.
%
function [i1Array, i2Array] = split_by_false(boolArray)
    % PROPOSAL: Function name?
    %   PROPOSAL: split_by_*
    %   PROPOSAL: group_by_*
    %   PROPOSAL: ~boolean
    %   PROPOSAL: ~false? ~true
    %   PROPOSAL: 
    %   NOTE: Compare strsplit, EJ_library.utils.split_by_jumps

    EJ_library.assert.vector(boolArray)
    
    % Add false components to
    % (1) make it easy to handle empty (zero length) array,
    % (2) make it easy to handle array's beginning and end.
    b = [false; boolArray(:); false];
    
    % NOTE: Indices same as in "b".
    bBegin = [~b(1:end-1) &  b(2:end)];
    bEnd   = [ b(1:end-1) & ~b(2:end)];
    
    % NOTE: i1/2Array indices same as in "boolArray" therefore -1.
    i1Array = find(bBegin) + 1 - 1;
    i2Array = find(bEnd)   + 0 - 1;
    
    % Enforce 0x1 arrays for empty arrays.
    if isempty(i1Array)
        i1Array = ones(0,1);
        i2Array = i1Array;
    end
end
