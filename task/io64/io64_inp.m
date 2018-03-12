function [cogent, byte] = inp(cogent, address)

% global cogent;

byte = io64(cogent.io.ioObj,address);
