function cmap1=irf_colormap(varargin)
% IRF_COLORMAP return colormap by name or apply and freeze the colormap
%
% CMAP = IRF_COLORMAP(colormap_name)
%  Colormap_names:
%       'standard'  - (default), same as 'space','cmap' (commonly used showing space data)
%       'poynting'  - white in center and blue/green for negative and red/black for positive values
%       'poynting_gray'  - gray in center and blue/green for negative and red/black for positive values
%       'solo'
%       'bluered'
%       'waterfall' - fancy-schmancy
%
% IRF_COLORMAP(AX,colormap_name) - apply colormap to axis AX


[ax,args,nargs] = axescheck(varargin{:});

if nargs == 0 % show only help
  help irf_colormap;
  return
end

% check which axis to apply
if isempty(ax)
  axes(gca);
else
  axes(ax(1));
end

colormap_name=args{1};

load caa/cmap.mat % default map
if nargs > 0
  switch lower(colormap_name)
    case 'poynting'
      it=0:.02:1;it=it(:);
      cmap=[ [0*it flipud(it) it];[it it it*0+1];[it*0+1 flipud(it) flipud(it)]; [flipud(it) 0*it 0*it]]; clear it;
    case {'poynting_grey','poynting_gray'}
      it=0:.02:1;it=it(:);
      cmap=[ [0*it flipud(it) it];...
        [it*.8 it*.8 it*0+1];...
        [it*0+1 flipud(it*.8) flipud(it*.8)];...
        [flipud(it) 0*it 0*it]];
      clear it;
    case 'solo'
      it=0:.02:1;it=it(:);
      cmap=[ [it it it*0+1];[it*0+1 flipud(it) flipud(it)]; [flipud(it) 0*it 0*it]]; clear it;
    case {'parula','jet','hsv','hot','cool','spring','summer','autumn',...
        'winter','gray','bone','copper','pink','lines','colorcube','prism','flag','white'}
      cmap = colormap(colormap_name);
    case {'bluered'}
      rr = interp1([1 64 128 192 256],[0.0  0.5 0.75 1.0 0.75],1:256);
      gg = interp1([1 64 128 192 256],[0.0  0.5 0.75 0.5 0.00],1:256);
      bb = interp1([1 64 128 192 256],[0.75 1.0 0.75 0.5 0.00],1:256);
      cmap = [rr' gg' bb'];
    case 'waterfall' % fancy-schmancy
      c = [55,137,187;...
        106,193,165;...
        172,220,166;...
        230,244,157;...
        255,254,194;...
        253,223,144;...
        251,173,104;...
        242,109,074;...
        211,064,082]/255;
      cmap = interp1(linspace(1,64,size(c,1)),c,1:64);
     case 'cubehelix' % stolen from matplotlib
        cmap = [0, 0, 0;
        1, 0, 1;
        3, 1, 3;
        4, 1, 4;
        6, 2, 6;
        8, 2, 8;
        9, 3, 9;
        10, 4, 11;
        12, 4, 13;
        13, 5, 15;
        14, 6, 17;
        15, 6, 19;
        17, 7, 21;
        18, 8, 23;
        19, 9, 25;
        20, 10, 27;
        20, 11, 29;
        21, 11, 31;
        22, 12, 33;
        23, 13, 35;
        23, 14, 37;
        24, 15, 39;
        24, 17, 41;
        25, 18, 43;
        25, 19, 45;
        25, 20, 47;
        26, 21, 48;
        26, 22, 50;
        26, 24, 52;
        26, 25, 54;
        26, 26, 56;
        26, 28, 57;
        26, 29, 59;
        26, 31, 60;
        26, 32, 62;
        26, 34, 63;
        26, 35, 65;
        25, 37, 66;
        25, 38, 67;
        25, 40, 69;
        25, 41, 70;
        24, 43, 71;
        24, 45, 72;
        24, 46, 73;
        23, 48, 74;
        23, 50, 74;
        23, 52, 75;
        23, 53, 76;
        22, 55, 76;
        22, 57, 77;
        22, 58, 77;
        21, 60, 77;
        21, 62, 78;
        21, 64, 78;
        21, 66, 78;
        21, 67, 78;
        21, 69, 78;
        20, 71, 78;
        20, 73, 78;
        20, 74, 77;
        21, 76, 77;
        21, 78, 77;
        21, 79, 76;
        21, 81, 76;
        21, 83, 75;
        22, 84, 75;
        22, 86, 74;
        22, 88, 73;
        23, 89, 73;
        23, 91, 72;
        24, 92, 71;
        25, 94, 70;
        26, 95, 69;
        27, 97, 68;
        27, 98, 67;
        28, 99, 66;
        30, 101, 66;
        31, 102, 65;
        32, 103, 64;
        33, 104, 63;
        35, 106, 61;
        36, 107, 60;
        38, 108, 59;
        39, 109, 58;
        41, 110, 58;
        43, 111, 57;
        45, 112, 56;
        47, 113, 55;
        49, 114, 54;
        51, 114, 53;
        53, 115, 52;
        55, 116, 51;
        57, 116, 51;
        60, 117, 50;
        62, 118, 49;
        65, 118, 49;
        67, 119, 48;
        70, 119, 48;
        72, 120, 47;
        75, 120, 47;
        78, 120, 47;
        81, 121, 46;
        83, 121, 46;
        86, 121, 46;
        89, 121, 46;
        92, 122, 46;
        95, 122, 47;
        98, 122, 47;
        101, 122, 47;
        104, 122, 48;
        107, 122, 48;
        110, 122, 49;
        113, 122, 50;
        116, 122, 50;
        120, 122, 51;
        123, 122, 52;
        126, 122, 53;
        129, 122, 55;
        132, 122, 56;
        135, 122, 57;
        138, 121, 59;
        141, 121, 60;
        144, 121, 62;
        147, 121, 64;
        150, 121, 65;
        153, 121, 67;
        155, 121, 69;
        158, 121, 71;
        161, 121, 74;
        164, 120, 76;
        166, 120, 78;
        169, 120, 81;
        171, 120, 83;
        174, 120, 86;
        176, 120, 88;
        178, 120, 91;
        181, 120, 94;
        183, 120, 96;
        185, 120, 99;
        187, 121, 102;
        189, 121, 105;
        191, 121, 108;
        193, 121, 111;
        194, 121, 114;
        196, 122, 117;
        198, 122, 120;
        199, 122, 124;
        201, 123, 127;
        202, 123, 130;
        203, 124, 133;
        204, 124, 136;
        205, 125, 140;
        206, 125, 143;
        207, 126, 146;
        208, 127, 149;
        209, 127, 153;
        209, 128, 156;
        210, 129, 159;
        211, 130, 162;
        211, 131, 165;
        211, 131, 169;
        212, 132, 172;
        212, 133, 175;
        212, 135, 178;
        212, 136, 181;
        212, 137, 184;
        212, 138, 186;
        212, 139, 189;
        212, 140, 192;
        211, 142, 195;
        211, 143, 197;
        211, 144, 200;
        210, 146, 203;
        210, 147, 205;
        210, 149, 207;
        209, 150, 210;
        208, 152, 212;
        208, 154, 214;
        207, 155, 216;
        207, 157, 218;
        206, 158, 220;
        205, 160, 222;
        205, 162, 224;
        204, 164, 226;
        203, 165, 227;
        203, 167, 229;
        202, 169, 230;
        201, 171, 231;
        201, 172, 233;
        200, 174, 234;
        199, 176, 235;
        199, 178, 236;
        198, 180, 237;
        197, 182, 238;
        197, 183, 239;
        196, 185, 239;
        196, 187, 240;
        195, 189, 241;
        195, 191, 241;
        194, 193, 242;
        194, 194, 242;
        194, 196, 242;
        193, 198, 243;
        193, 200, 243;
        193, 202, 243;
        193, 203, 243;
        193, 205, 243;
        193, 207, 243;
        193, 208, 243;
        193, 210, 243;
        193, 212, 243;
        193, 213, 243;
        194, 215, 242;
        194, 216, 242;
        195, 218, 242;
        195, 219, 242;
        196, 221, 241;
        196, 222, 241;
        197, 224, 241;
        198, 225, 241;
        199, 226, 240;
        200, 228, 240;
        200, 229, 240;
        202, 230, 239;
        203, 231, 239;
        204, 232, 239;
        205, 233, 239;
        206, 235, 239;
        208, 236, 238;
        209, 237, 238;
        210, 238, 238;
        212, 239, 238;
        213, 240, 238;
        215, 240, 238;
        217, 241, 238;
        218, 242, 238;
        220, 243, 239;
        222, 244, 239;
        223, 244, 239;
        225, 245, 240;
        227, 246, 240;
        229, 247, 240;
        231, 247, 241;
        232, 248, 242;
        234, 248, 242;
        236, 249, 243;
        238, 250, 244;
        240, 250, 245;
        242, 251, 246;
        244, 251, 247;
        245, 252, 248;
        247, 252, 249;
        249, 253, 250;
        251, 253, 252;
        253, 254, 253;
        255, 255, 255] / 255;
      
  end
end

if nargout == 0 % apply the colormap and freeze
  colormap(cmap);
  freezeColors;
  hcb = cbhandle;
  if hcb % workaround cbfreeze bug that cbfreeze removes cblabel
    hy=get(hcb,'ylabel');
    ylabel_string=get(hy,'string');
    ylabel_fontsize=get(hy,'fontsize');
    new_hcb = cbfreeze(hcb);
    new_hy=get(new_hcb,'ylabel');
    set(new_hy,'string',ylabel_string,'fontsize',ylabel_fontsize);
  end
  %    cbfreeze;
elseif nargout == 1 % only return colormap
  cmap1=cmap;
end

