function data = enUtil_averageReference(data)
% data should be chan x time x epochs
data = bsxfun(@minus, data, sum(data,1) / (size(data,1) + 1));
end
