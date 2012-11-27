classdef TimeTable
	% irf.TimeTable class to handle time tables
	%
	% TT=irf.TimeTable	- generate empty time table
	% TT=irf.TimeTable('demo') - generate short example time table
	% TT=irf.TimeTable('http://..') - load ascii time table from internet link 
	% TT=irf.TimeTable(filename) - load ascii time table form file
	% TT=irf.TimeTable(ascii_text) - load time table from cell string array ascii_text
	%
	% N = numel(TT)		- number of time intervals
	% out = ascii(TT)	- time table in ascii format
	% TT = add(TT,..)	- add time interval to table, see help irf.TimeTable.add
	% export(TT,filename) - export time table to file
	% 
	% Examples:
	%	TT = irf.TimeTable % initialize empty time table
	%	tint=irf_time([2001 1 1 0 0 0]) + [0 3600];
	%	TT=add(TT,tint,{'Burst events','all tail crossings 2001'},'this is best event');
	%	TT=add(TT,tint+7200,{},'this is another best');
	%	ascii(TT)
	%   
	%   %read Cluster Master Science Plan
	%   msp=irf.TimeTable('http://jsoc1.bnsc.rl.ac.uk/msp/full_msp_ascii.lst');

	% The following properties can be set only by class methods
	properties (SetAccess = public)
		Header
		TimeInterval
		Comment
		Description
	end
	methods
		function TT		= TimeTable(varargin) % construct time table
			TT.Header={};		%	header for file, cell string array
			TT.TimeInterval=[];	%	matrix with 2 columns, start/end
			TT.Comment={};		%	short comment for each time interval
			TT.Description={};	%	description lines for each interval
			if numel(varargin)==1,
				source = varargin{1};
			elseif numel(varargin)==0,
				return;
			else
				irf_log('fcal','max 1 argument supported');
				return
			end
			if ischar(source) && size(source,1)==1
				if strcmpi(source,'demo') % return demo time table
					TT = irf.TimeTable; % initialize empty time table
					tint=irf_time([2001 1 1 0 0 0]) + [0 3600];
					TT.Header = {'This is header','Where general file information is given'};
					TT=add(TT,tint,{'These are several lines','describing the time interval'},'this is comment');
					TT=add(TT,tint+7200,{},'this is comment, there is no description for this time interval');
					TT=add(TT,tint+600,{},'this is overlapping interval');
				elseif strfind(source,'http:')==1 % start with http://
					tempTT = urlread(source);
					TT	 = irf.TimeTable(tempTT);
				elseif exist(source,'file') % check if file
					fid = fopen(source);
					fileContents=fscanf(fid,'%c',inf);
					fclose(fid);
					TT=irf.TimeTable(fileContents);
				else % assume source is ascii text of time table
					ttAscii=textscan(source,'%s','delimiter',sprintf('\n'));
					TT=irf.TimeTable(ttAscii{1});
					return;
				end
			elseif iscellstr(source) % source is ascii text to be converted
				% TT   = from_ascii(ascii)
				% convert ascii to time table
				% function out=from_ascii(ttascii) % convert ascii tt to matlab format
				TT=irf.TimeTable;
				
				isHeader					= 1;
				iHeaderLine					= 0;
				nTimeInterval				= 0;
				header				    	= cell(size(source,1));
				description			    	= cell(size(source,1));
				iDescriptionLine			= 0;
				for iTtAscii=1:numel(source)
					str=source{iTtAscii};
					timeInterval=regexp(str,'^\s*(?<start>[\d-]*T[\d:\.]*Z?)\s*(?<end>[\d-]*T[\d:\.]*Z?)\s?(?<comment>.*)','names');
					if ~isempty(timeInterval) && isfield(timeInterval,'start') && isfield(timeInterval,'end')
						isHeader=0;
						nTimeInterval=nTimeInterval+1;
						TT.TimeInterval(nTimeInterval,:) = [irf_time(timeInterval.start,'iso2epoch') irf_time(timeInterval.end,'iso2epoch')];
						if isfield(timeInterval,'comment'),
							TT.Comment{nTimeInterval}	= timeInterval.comment;
						else
							TT.Comment{nTimeInterval}	= [];
						end
						if nTimeInterval>1,
							TT.Description{nTimeInterval-1}	= description(1:iDescriptionLine);
						end
						iDescriptionLine				= 0;  % reset counter of description lines for the next time interval
					else
						if isHeader
							iHeaderLine = iHeaderLine + 1;
							header{iHeaderLine} = str;
						else
							iDescriptionLine = iDescriptionLine + 1;
							description{iDescriptionLine} = str;
						end
					end
				end
				TT.Description{nTimeInterval}=description(1:iDescriptionLine);
				TT.Header = header(1:iHeaderLine);
			elseif isnumeric(source) && size(source,2)==2 % time interval
				TT.TimeInterval	= source;
				TT.Header		= {};
				TT.Comment		= cell(size(source,1),1);
				TT.Description	= cell(size(source,1),1);
			else
				irf_log('fcal','Unknown argument.');
				return;
			end
		end
		function N		= numel(TT)
			N = numel(TT.TimeInterval)/2;
		end
		function TT		= add(TT,tint,description,comment)
			% TT = add(TT,tint,description,comment)
			% add element to time table
			% tint - time interval, vector with start and end time in epoch
			%			or time interval in iso format
			% description - cell string array describing time interval
			% comment - character vector commenting time interval (in ascii format
			%				located on the same line)
			if nargin<4, comment='';end
			if nargin<3, description={};end
			if nargin<2, irf_log('fcal','not enough arguments');return;end
			nElement=size(TT.TimeInterval,1)+1;
			if isnumeric(tint),
				if numel(tint)==0,
					irf_log('fcal','Time interval not specified. Returning.');
					return;
				elseif numel(tint)==1, % only time instant give, end the same as start time
					tint(2)=tint(1);
				end
			elseif ischar(tint) % assume iso format
				tint=irf_time(tint,'iso2tint');
			end
			TT.TimeInterval(nElement,:)=tint;
			if ~iscellstr(description), % description should be cellstr
				if ischar(description)
					description={description};
				else
				end
			end
			TT.Description{nElement}=description;
			if ischar(comment),
				TT.Comment{nElement}=comment;
			else
				TT.Comment{nElement}=[];
			end
		end
		function out	= ascii(tt) % tt in ascii format
			% Return time table in ascii format (cell string array)
			header=tt.Header;
			tint=tt.TimeInterval;
			description=tt.Description;
			comment=tt.Comment;
			nElements=numel(tt);
			nHeaderLines=numel(header);
			nDescriptionLines=0;
			for j=1:nElements,
				nDescriptionLines=nDescriptionLines+numel(description{j});
			end
			out=cell(nHeaderLines+nElements+nDescriptionLines,1);
			out(1:nHeaderLines)=header;
			currentLine=nHeaderLines+1;
			for iTT=1:numel(tt)
				fmt='%s %s %s';
				out{currentLine}=sprintf(fmt,irf_time(tint(iTT,1),'iso'),...
					irf_time(tint(iTT,2),'iso'),comment{iTT});
				currentLine=currentLine+1;
				for j=1:numel(description{iTT}),
					out{currentLine}=description{iTT}{j};
					currentLine=currentLine+1;
				end
			end
			if nargout == 0, % interactive calling from command line
				out=char(out);
				if size(out,1)>10,
					disp(out(1:7,:));
					disp(['.... ' num2str(size(out,1)-10) ' lines ommitted.....']);
					disp(out(end-2:end,:));
				else
					disp(out);
				end
				clear out;
			end
		end
		function ok		= export_ascii(TT,filename) % export to file
			% ok = export_ascii(TT,filename)
			%	export time table TT to file 
			out=ascii(TT);
			if ischar(filename) % read from file
				fid = fopen(filename,'w');
				if fid == -1,
					irf_log('fcal',['Cannot open file:' filename]);
					ok=0;
					return;
				end
				for j=1:numel(out),
					fprintf(fid,'%s\n',out{j});
				end
				fclose(fid);
				ok=1;
				if nargout==0, clear ok, end;
			end
		end
		function TTout  = select(TTin,index) % return index
			TTout=[];
			if ~isnumeric(index)
				irf_log('fcal','Index not number');
				return;
			end
			if max(index(:)) > numel(TTin) || min(index(:)) < 1,
				irf_log('fcal','Index out of range');
				return;
			end
			TTout				= irf.TimeTable;
			TTout.TimeInterval  = TTin.TimeInterval(index(:),:);
			TTout.Comment		= TTin.Comment(index(:));
			TTout.Description   = TTin.Description(index(:));
		end
		function TTout	= unique(TTin) % time table sorted and unique
			TTout=TTin;
			tt=TTin.TimeInterval;
			com=TTin.Comment;
			desc=TTin.Description;
			[~,inew]=sort(tt(:,1));
			ttnew=tt(inew,:);
			iJoinedLines=zeros(numel(inew),1);
			for j=numel(inew):-1:2
				if ttnew(j,1)<ttnew(j-1,2),
					iJoinedLines(j)=1;
					ttnew(j-1,2)=max(ttnew(j-1,2),ttnew(j,2));
					ttnew(j,:)=[];
				end
			end
			TTout.TimeInterval = ttnew;
			com = com(inew);
			TTout.Comment = com(~iJoinedLines);
			desc = desc(inew);
			TTout.Description = desc(~iJoinedLines);
		end
		function TT		= intersect(TT1,TT2) % intersect of 2 time tables
			TT1 = unique(TT1);
			TT2 = unique(TT2);
			t1=TT1.TimeInterval;
			t2=TT2.TimeInterval;
			tout=t1;
			iInterval=0;
			i2=1;
			for j= 1:size(t1,1),
				while (t1(j,1)>t2(i2,2))
					i2=i2+1;
					if i2>size(t2,1), break;end % end of 2nd time series
				end
				if i2>size(t2,1), break;end % end of 2nd time series
				while t2(i2,1)<t1(j,2)
					iInterval=iInterval+1;
					tout(iInterval,:)=[max(t1(j,1),t2(i2,1)) min(t1(j,2),t2(i2,2))];
					i2=i2+1;
					if i2>size(t2,1), break;end % end of 2nd time series
				end
				if i2>size(t2,1), break;end % end of 2nd time series
			end
			tout(iInterval+1:end,:)=[];
			TT = irf.TimeTable;
			TT.Header = [cellfun(@(x) {['# ' x]}, TT1.Header),...
				'INTERSECT',cellfun(@(x) {['# ' x]}, TT2.Header)];
			TT.TimeInterval=tout;
			TT.Comment=cell(1,size(tout,1));
			TT.Description=cell(1,size(tout,1));
		end
	end % methods
end % classdef
