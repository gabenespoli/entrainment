function makeSureFoldersExist(varargin)
% loops through input args, checks if its a dir, creates it if it isn't
% and notifies the user

for i = 1:length(varargin)
    folder = varargin{i};

    if ~exist(folder, 'dir')
        fprintf('Creating folder ''%s''... ', folder)
        mkdir(folder)
        fprintf('Done.\n')
    end

end
