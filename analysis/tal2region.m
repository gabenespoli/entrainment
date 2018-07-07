%TAL2REGION  Convert Talairach coordinates to brain region labels.
%   The talairach.jar file must be in the same folder as tal2region.m,
%   and the computer must have an active internet connection. See 
%   http://www.talairach.org/manual.html#CommandLine for more info about
%   the talairach daemon.
%
% Usage:
%     region = tal2region(talcoords)
%     region = tal2region(talcoords, cubesize)
%
% Input:
%     talcoords   = [numeric N-by-3] Matrix of [x y z] Talairach
%                   coordinates.
%
%     cubesize    = [0:5] Size of cube in +/- mm to search for labels. If
%                   multiple labels are found, then multiple labels
%                   are returned. Entering 0 returns the closest gray 
%                   matter regardless of cube size. Note that cubesize is
%                   +/-, so for e.g. a cubesize of 2 will return labels
%                   contained within a cube that is 5 x 5 x 5 mm.
%                   You cannot specify more than one cubesize. Default 0.
%
% Output:
%     region      = [struct] Structure with fields corresponding to the
%                   different levels of labels (see bottom of this function
%                   or http://www.talairach.org/labels.html for a complete 
%                   list): Hemisphere, Lobe, Gyrus, Tissue Type, and Cell 
%                   Type. Each field is an N-by-1 cell array.
%
% Written by Gabriel A. Nespoli 2016-04-23. Revised 2016-08-12.

function region = tal2region(coords, cubesize, verbose)

% defaults
if nargin < 2, cubesize = 0; end
if nargin < 3, verbose = true; end

% parse input
if iscolumn(coords), coords = transpose(coords); end
if size(coords, 2) ~= 3, error('Problem with TALCOORDS.'), end
coords = round(coords, 4);

% change to folder with talairach.jar and tal2region.m
currentFolder = cd;
cd(fileparts(mfilename('fullpath')))

% write coords to temporary text file
% name = tempname;
name = 'tal2region_data';
txtname = [name, '.txt'];
fid = fopen(txtname,'w');
temp = transpose(coords); % transpose so that it can be written element-wise
fprintf(fid,repmat('%f\t%f\t%f\n', 1, size(coords, 1)), temp(:));
fclose(fid);

% create system command & format for reading output
switch cubesize
    case 0
        cubestr = '4';
        formatStr = '%f%f%f%s%s%s%s%s';
        
    case {1,2,3,4,5}
        cubestr = ['3:', num2str(cubesize * 2 + 1)];
        formatStr = '%f%f%f%d%s%s%s%s%s%s';
        
    otherwise
        error('Invalid CUBESIZE.')
end

% run from system command line (i.e., terminal)
if verbose
    fprintf(['  Querying talairach.org database ', ...
            'with a cubesize of %i...'], cubesize)
end
com = ['java -cp talairach.jar org.talairach.ExcelToTD ', cubestr, ', ', txtname];
[status, result] = system(com);
if verbose, fprintf(' Done.\n'), end
if status, disp(result), end

% read coords from text file
tdname = [name, '.txt.td'];
if ~exist(tdname, 'file')
    error('td file doesn''t exist')
end
fid = fopen(tdname);
out = textscan(fid, formatStr, 'delimiter', '\t');
fclose(fid);

% delete temporary files
% if isunix
    % delcom = 'rm ';
% elseif ispc
    % delcom = 'del ';
% end
% system([delcom, txtname]);
% system([delcom, tdname]);

% switch back to original current folder
cd(currentFolder) 

% parse output
if cubesize == 0
    adj = -1;
else
    adj = 0;
end
% grayMatterInd = strcmp(out{8+adj},'Gray Matter'); % restrict to gray matter
regionCoords = [out{1}, out{2}, out{3}]; % concatenate coords that were returned
% regionCoords = regionCoords(grayMatterInd,:);
regionCoordsStr = cellstr(num2str(regionCoords));
coordsStr = cellstr(num2str(coords));

% get regions for each coord
region.cubesize = cubesize;
region.talcoords = coords;
regionTypes = {'hemisphere', 'lobe', 'gyrus', 'tissueType', 'cellType'};
for i = 1:length(regionTypes)
    region.(regionTypes{i}) = cell(size(coords, 1), 1);
end

for j = 1:length(coordsStr)
    ind = strcmp(regionCoordsStr, coordsStr(j));
    for i = 1:length(regionTypes)
        regionInd = i + 4;
        region.(regionTypes{i}){j} = unique(out{regionInd+adj}(ind));
        
        % remove asterisks
        rmInd = ismember(region.(regionTypes{i}){j}, '*');
        region.(regionTypes{i}){j}(rmInd) = [];
    end
end

end

% Level 1: Hemisphere
% -------------------
% Left Cerebrum
% Right Cerebrum
% Left Cerebellum
% Right Cerebellum
% Left Brainstem
% Right Brainstem
% Inter-Hemispheric

% Level 2: Lobe
% -------------
% Anterior Lobe
% Frontal Lobe
% Frontal-Temporal Space
% Limbic Lobe
% Medulla
% Midbrain
% Occipital Lobe
% Parietal Lobe
% Pons
% Posterior Lobe
% Sub-lobar
% Temporal Lobe

% Level 3: Gyrus
% --------------
% Angular Gyrus
% Anterior Cingulate
% Caudate
% Cerebellar Lingual
% Cerebellar Tonsil
% Cingulate Gyrus
% Claustrum
% Culmen
% Culmen of Vermis
% Cuneus
% Declive
% Declive of Vermis
% Extra-Nuclear
% Fastigium
% Fourth Ventricle
% Fusiform Gyrus
% Inferior Frontal Gyrus
% Inferior Occipital Gyrus
% Inferior Parietal Lobule
% Inferior Semi-Lunar Lobule
% Inferior Temporal Gyrus
% Insula
% Lateral Ventricle
% Lentiform Nucleus
% Lingual Gyrus
% Medial Frontal Gyrus
% Middle Frontal Gyrus
% Middle Occipital Gyrus
% Middle Temporal Gyrus
% Nodule
% Orbital Gyrus
% Paracentral Lobule
% Parahippocampal Gyrus
% Postcentral Gyrus
% Posterior Cingulate
% Precentral Gyrus
% Precuneus
% Pyramis
% Pyramis of Vermis
% Rectal Gyrus
% Subcallosal Gyrus
% Sub-Gyral
% Superior Frontal Gyrus
% Superior Occipital Gyrus
% Superior Parietal Lobule
% Superior Temporal Gyrus
% Supramarginal Gyrus
% Thalamus
% Third Ventricle
% Transverse Temporal Gyrus
% Tuber
% Tuber of Vermis
% Uncus
% Uvula
% Uvula of Vermis

% Level 4: Tissue Type
% --------------------
% Cerebro-Spinal Fluid
% Gray Matter
% White Matter

% Level 5: Cell Type
% ------------------
% Amygdala
% Anterior Commissure
% Anterior Nucleus
% Brodmann areas
% Caudate Body
% Caudate Head
% Caudate Tail
% Corpus Callosum
% Dentate
% Hippocampus
% Hypothalamus
% Lateral Dorsal Nucleus
% Lateral Geniculum Body
% Lateral Globus Pallidus
% Lateral Posterior Nucleus
% Mammillary Body
% Medial Dorsal Nucleus
% Medial Geniculum Body
% Medial Globus Pallidus
% Midline Nucleus
% Optic Tract
% Pulvinar
% Putamen
% Red Nucleus
% Substania Nigra
% Subthalamic Nucleus
% Ventral Anterior Nucleus
% Ventral Lateral Nucleus
% Ventral Posterior Lateral Nucleus
% Ventral Posterior Medial Nucleus

