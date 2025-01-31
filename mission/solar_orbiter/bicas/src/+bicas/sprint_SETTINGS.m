%
% Create human-readable multi-line string to represent SETTINGS. Meant for
% logging and printing to stdout.
%
%
% Author: Erik P G Johansson, IRF, Uppsala, Sweden
% First created 2017-02-22
%
function str = sprint_SETTINGS(SETTINGS)
    
    % PROPOSAL: Make hierarchy visually clearer?!!! Should then have help from data structure itself.
    %
    % PROPOSAL: Print more information.
    %   PROPOSAL: First column of characters to represent how values have been overridden and where.
    %       Ex: C    OUTPUT_CDF.WRITE_POLICY        % C  = Config file (once)
    %       Ex: CC   OUTPUT_CDF.WRITE_POLICY        % CC = Config file twice (or more)
    %       Ex: C AA OUTPUT_CDF.WRITE_POLICY        % C  = Config file (once), overridden by CLI argument (twice or more)
    %   PROPOSAL: Extra indented rows when default value is overridden.
    %       NOTE: Must be clear which values are actually used. Not to be confused with overridden values.
    %       OUTPUT_CDF.WRITE_POLICY = <value actually used>
    %           Default      = ...
    %           Config file  = ...
    %           Config file  = ...   % Second value in config file.
    %           CLI argument = ...
    %       CON: Slightly less clear when not having a separat column for overriding.
    %       PRO: Can handle any situation of overriding.
    
    % IMPLEMENTATION NOTE: Only prints "Settings" as a header (not "constants")
    % to indicate/hint that it is only the content of the "SETTINGS" variables,
    % and not of bicas.constants.
    str = sprintf([...
        '\n', ...
        'SETTINGS\n', ...
        '========\n']);
    
    % Values seem sorted from the method, but sort again just to be sure.
    keyList      = sort(SETTINGS.get_keys());   
    lengthMaxKey = max(cellfun(@length, keyList));
    
    
    
    for iKey = 1:length(keyList)
        key   = keyList{iKey};
        valueStructArray = SETTINGS.get_final_value_array(key);
        %value = valueStructArray(end).value;
        nValues = numel(valueStructArray);
        
        %======================================================================
        % Derive value strings for all historical values: present and previous
        % ones
        %======================================================================
        strValueList = {};   % Must be reset for every key.
        for iVs = 1:nValues    % Iterate over versions of the same setting.
            value = valueStructArray(iVs).value;
            try
                displayStr = bicas.settings_value_to_display_str(value);
            catch Exc
                error(...
                    'BICAS:Assertion', ...
                    ['SETTINGS value (overriden or not) for key="%s"', ...
                    ' can not be converted to a display string.', ...
                    ' This is likely a bug.'], ...
                    key)
            end
            strValueList{iVs} = displayStr;
        end
        
        valueStatusStr = EJ_library.utils.translate({...
            {'default'},            '  --';
            {'configuration file'}, '(conf)';
            {'CLI arguments'},      '(CLI)'}, ...
            valueStructArray(end).valueSource, ...
            'BICAS:Assertion', ...
            'Illegal setting value source');
        
        str = [str, sprintf(...
            ['%-6s  %-', int2str(lengthMaxKey),'s = %s\n'], ...
            valueStatusStr, key, strValueList{end})];
        
    end
    
    str = [str, newline];
    str = [str, sprintf('Explanations for leftmost column above:\n')];
    str = [str, sprintf('---------------------------------------\n')];
    str = [str, sprintf('  --   = Default value\n')];
    str = [str, sprintf('(conf) = Value comes from configuration file\n')];
    str = [str, sprintf('(CLI)  = Value comes from CLI argument\n')];
    
    str = [str, newline];
    
end
