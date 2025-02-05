function [smallChanges,bigChanges, sizeThresh] = getSmallBigChanges(changeMap,thresh_method,man_thresh,doPlot)
%GETSMALLBIGCHANGES returns two binary images smallChanges and bigChanges,
% representing Regions of a changeMap that are smaller and bigger than a
% specified or dynamically evaluated threshold



% Check if changeMap is logical array
I = im2bw(changeMap);
%Label Regions and extract Area information
L = bwlabel(I);
s = regionprops(L,'Area');
s = struct2array(s);

%Set Area Threshold
if (strcmp(thresh_method, 'mean'))
    sizeThresh = mean(s);
elseif (strcmp(thresh_method,'median'))
    sizeThresh = median(s);
elseif (strcmp(thresh_method, 'manual'))
    sizeThresh = man_thresh;
end

%Find Regions with Area below and above Thresh
smallReg = find(s < sizeThresh);
bigReg = find(s >= sizeThresh);


%Iterate over all regions and build up both change maps
smallChanges = zeros(size(I));
bigChanges = zeros(size(I));

for i = 1:size(smallReg,2)
    smallChanges = or(smallChanges,(L == smallReg(i)));
end
for i = 1:size(bigReg,2)
    bigChanges = or(bigChanges, (L == bigReg(i)));
end

%Plot if you want
if doPlot
    figure
    subplot(1,2,1)
    imshow(smallChanges)
    title(sprintf('Small Changes, Thresh = %.0f',sizeThresh))
    subplot(1,2,2)
    imshow(bigChanges)
    title(sprintf('Big Changes, Thresh = %.0f',sizeThresh))
end
end

