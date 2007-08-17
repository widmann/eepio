function [padArr] = zeropad(arr, width, dim)

if nargin < 3 || isempty(dim)
    dim = 1;
end

padSize = size(arr);
padSize(dim) = width - padSize(dim);

padArr = cat(dim, arr, cast(zeros(padSize), class(arr)));
