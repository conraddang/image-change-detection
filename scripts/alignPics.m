function [pic1_crop pic1_crop_gray  pic2_crop pic2_crop_gray pic2_crop_bright pic2_crop_bright_gray] = alignPics(pic1, pic2, doText, doPlot)
%alignPics Alligns two rgb picture in terms of rotation, translation, scale and color distribution
%   
%   [pic1_crop pic1_crop_gray  pic2_crop_bright pic2_crop_bright_gray] = alignPics(pic1, pic2, doText, doPlot)
%       returns pic1_crop (a RGB representation of Picture1 where only areas that are
%       common in both pictures are neq zero), pic1_crop_gray (a grayscale
%       version of the above), pic2_crop (a RGB represenation of pic2,
%       that is adjusted to Pic1 in terms of rotation, translation and scale),
%       pic2_crop_gray (a grayscale version of the above), pic2_crop_bright
%       (a RGB represenation of pic2,
%       that is adjusted to Pic1 in terms of rotation, translation, scale and
%       color distribution), pic2_crop_bright_gray (a grayscale
%       version of the above)


%Cut out Google stuff
%pic1 = pic1(70:1000,:,1:3);
%pic2 = pic2(70:1000,:,1:3);
imgheight = round(size(pic1,1) - 0.07*size(pic1,1));
pic1 = pic1(round(0.07*size(pic1,1)):imgheight,:,1:3);
imgheight = round(size(pic2,1) - 0.07*size(pic2,1));
pic2 = pic2(round(0.07*size(pic2,1)):imgheight,:,1:3);

%Adjust Colors
%create adjusted Pic2 with Histogram of Pic1
[pic2_bright, histgram1] = imhistmatch(pic2, pic1, 255);

%convert both Pics to gray
pic2_bright_gray = rgb2gray(pic2_bright);
pic1_gray = rgb2gray(pic1);
pic2_gray = rgb2gray(pic2);

if doPlot
    %Plot Comparison of original Pics and original Pic1 and adjusted Pic2
    figure; %fig1
    imshow([pic1,pic2]);
    title('Left: Pic1, Right:  Pic2')
    figure; %fig2
    imshow([pic1,pic2_bright]);
    title('Left: Pic1, Right: Color Adjusted Pic2')
end

%% Detect and extract features in both images.
if doText
    disp('+++START SURF MATLAB+++')
    disp('---Feature Detection and Extraction---')
    tic
end
%Set Number of Features
numMax = 20000;

%Detect and Filter features
pointsPic1 = detectSURFFeatures(pic1_gray); %'NumLevels', 6 this decreases features but on what grounds?
pointsPic2 = detectSURFFeatures(pic2_bright_gray);
pointsPic1_red = selectStrongest(pointsPic1,numMax);
pointsPic2_red = selectStrongest(pointsPic2,numMax);

%Extract Features
[featuresPic1, valid_pointsPic1] = extractFeatures(pic1_gray, pointsPic1_red);
[featuresPic2, valid_pointsPic2] = extractFeatures(pic2_bright_gray, pointsPic2_red);

if doText
    toc
    disp(sprintf('%d and %d features were detected',size(valid_pointsPic1,1),size(valid_pointsPic2,1)))
end
%% Match features
if doText
    disp('---Feature Matching---')
    tic
end
indexPairs = matchFeatures(featuresPic1, featuresPic2, 'MatchThreshold', 70,'Unique',true);

matchedPic1  = valid_pointsPic1.Location(indexPairs(:,1),:);
matchedPic2 = valid_pointsPic2.Location(indexPairs(:,2),:);

if doText
    toc
    disp(sprintf('%d features were matched',size(indexPairs,1)))
end

%% Plot Matches
if doPlot
    figure; %fig2
    
    %Plot Found Features in Pic1_gray
    subplot(1,2,1)
    imshow(pic1_gray); hold on;
    plot(valid_pointsPic1,'showOrientation',true);
    title("Original with " + size(valid_pointsPic1,1) + " Keypoints");
    
    %Plot Found Features in Pic2_bright_gray
    subplot(1,2,2)
    imshow(pic2_bright_gray); hold on;
    plot(valid_pointsPic2,'showOrientation',true);
    title("Distorted with " + size(valid_pointsPic2,1) + " Keypoints");
    
    
    figure %fig3
    %Plot Matches between gray Pics
    imshow([pic1_gray,pic2_bright_gray]);hold on;
    xshift = size(pic1_gray,2);
    
    plot(matchedPic1(:,1),matchedPic1(:,2),'rx')
    plot(matchedPic2(:,1)+xshift,matchedPic2(:,2),'gx')
    
    for i = 1:size(matchedPic1,1)
        line([matchedPic1(i,1), matchedPic2(i,1)+xshift],[matchedPic1(i,2), matchedPic2(i,2)],'LineWidth',2)
    end
    title('Matches');
    
end



%% Estimate Transformation

if (size(indexPairs,1)>1)
    [tform, inlierDistorted, inlierOriginal] = estimateGeometricTransform(...
        matchedPic2, matchedPic1, 'similarity');
    
   
   
    % Compute the inverse transformation matrix.
    Tinv  = tform.invert.T;
    
    ss = Tinv(2,1);
    sc = Tinv(1,1);
    scaleRecovered = sqrt(ss*ss + sc*sc);
    thetaRecovered = atan2(ss,sc)*180/pi;
    
    if doText
        disp(sprintf('Determined %.0f degrees rotation.',mod(thetaRecovered,360)));
        disp(sprintf('Determined a zoom factor of %.1f.',scaleRecovered));
    end
end
%% Align Pic2 to Pic1 in terms of rotation, scale and translation

outputView = imref2d(size(pic1_gray));

pic2_crop_bright_gray  = imwarp(pic2_bright_gray,tform,'OutputView',outputView);
pic2_crop_bright = imwarp(pic2_bright,tform,'OutputView',outputView);

pic2_crop_gray  = imwarp(pic2_gray,tform,'OutputView',outputView);
pic2_crop = imwarp(pic2,tform,'OutputView',outputView);


%% Crop Pic1
mask = double(pic2_crop_bright_gray ~= 0);


pic1_crop(:,:,1) = mask.*pic1(:,:,1);
pic1_crop(:,:,2) = mask.*pic1(:,:,2);
pic1_crop(:,:,3) = mask.*pic1(:,:,3);

pic1_crop_gray = mask.*pic1_gray;


if doPlot
    figure, imshowpair(pic1_crop_gray,pic2_crop_gray,'montage')%fig4
    hold on
    title('Aligned Pic1 and Pic2');
    
end


end