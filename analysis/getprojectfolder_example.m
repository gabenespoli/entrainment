function project_folder = get_project_folder
% this function is a helper function for getpath.m
% it should return the absolute path to the root directory for this project
% use the fullfile function to make this OS agnostic
% e.g., project_folder = fullfile('/Users','gmac','local','en');

project_folder = fullfile('/Users','gmac','local','en');

end
