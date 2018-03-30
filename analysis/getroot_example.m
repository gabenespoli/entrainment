function project_folder = getroot
% This function is a helper function for getpath.m. It should return the
%   absolute path to the root directory for this project.
%
% Instructions:
%   Make a copy of this file and name it getroot.m. Edit the file
%   so that it sets the value of the project_folder variable to be the root
%   folder of this project. i.e., the "project_folder" folder as indicated
%   in the "The Project Folder" section of the README. Use the `fullfile`
%   function so that this will work on Linux, Mac, and Windows.

project_folder = fullfile('/Users','gmac','local','en');

end
