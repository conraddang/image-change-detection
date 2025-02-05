function [cluster_mask ,pic1_clusterColors, pic2_clusterColors ] = clusterChanges(image1_crop,image1_crop_gray,image2_crop,image2_crop_gray, change_map,doText,doPlot)

%% Get Rectangular Change Mask
%Gray
mask_gray = change_map(1:size(image1_crop_gray,1),1:size(image1_crop_gray,2));
%RGB
mask(:,:,1) = mask_gray;
mask(:,:,2) = mask_gray;
mask(:,:,3) = mask_gray;

%Get Portions of Pic1 and Pic2 that changed
pic1_changed_gray = mask_gray .* image1_crop_gray;
pic2_changed_gray = mask_gray .* image2_crop_gray;

pic1_changed = mask .* image1_crop;
pic2_changed = mask .* image2_crop;

if doPlot
    figure;
    imshow(pic1_changed_gray);
    figure;
    imshow(pic2_changed_gray);
    
    figure;
    imshow(pic1_changed);
    figure;
    imshow(pic2_changed);
end
%% Determine number of Clusters
%via number of local maxima in the summed histograms of the changed areas
%in grayscale pic1 and pic2

%Get Histograms of Grayscale change areas
pic1_gray_hist = imhist(pic1_changed_gray);
pic1_gray_hist = pic1_gray_hist(2:end-1);

pic2_gray_hist = imhist(pic2_changed_gray);
pic2_gray_hist = pic2_gray_hist(2:end-1);
if doPlot
    figure
    plot(pic1_gray_hist(2:end-1)); hold on;
    plot(pic2_gray_hist(2:end-1))
    title('Gray Histogramms');
end
%Smooten sum of Histograms

sum_gray_hist = pic1_gray_hist + pic2_gray_hist;

%Running average filter
windowSize = 5;
b = (1/windowSize)*ones(1,windowSize);
a = 1;
gray_hist_smoothed = filter(b,a,sum_gray_hist);

%Find local Maxima
maxCluster = 5;
minProminence = 200;
[is_localMax, prominence] = islocalmax(gray_hist_smoothed,'MinProminence',minProminence,'MaxNumExtrema',maxCluster);
index_localMax = find(is_localMax);

%Set number of clusters to number of prominent Maxima
k = max(1,length(index_localMax));

if doPlot
    figure
    plot(gray_hist_smoothed)
    hold on
    plot(sum_gray_hist)
    plot(prominence)
    plot(index_localMax,sum_gray_hist(index_localMax),'rx')
    title('Gray Histogramm');
end
%% Cluster change pixels

%Get index of changed Pixels
changed_pixels_ind = find(mask_gray);

%Smooten cropped images and sort changed pixels into column vector

image_1_crop_smooth = imfilter(image1_crop,fspecial('gaussian',20,10));

image1_crop_R = image_1_crop_smooth(:,:,1);
image1_crop_R = image1_crop_R(:);
image1_crop_G = image_1_crop_smooth(:,:,2);
image1_crop_G = image1_crop_G(:);
image1_crop_B = image_1_crop_smooth(:,:,3);
image1_crop_B = image1_crop_B(:);

image_2_crop_smooth = imfilter(image2_crop,fspecial('gaussian',20,10));

image2_crop_R = image_2_crop_smooth(:,:,1);
image2_crop_R = image2_crop_R(:);
image2_crop_G = image_2_crop_smooth(:,:,2);
image2_crop_G = image2_crop_G(:);
image2_crop_B = image_2_crop_smooth(:,:,3);
image2_crop_B = image2_crop_B(:);

feature_Vector(1,:) = image1_crop_R(changed_pixels_ind);
feature_Vector(2,:) = image1_crop_G(changed_pixels_ind);
feature_Vector(3,:) = image1_crop_B(changed_pixels_ind);
feature_Vector(4,:) = image2_crop_R(changed_pixels_ind);
feature_Vector(5,:) = image2_crop_G(changed_pixels_ind);
feature_Vector(6,:) = image2_crop_B(changed_pixels_ind);

% feature_Vector(1,:) = image1_crop_R(indexes)-image2_crop_R(indexes);
% feature_Vector(2,:) = image1_crop_G(indexes)-image2_crop_G(indexes);
% feature_Vector(3,:) = image1_crop_B(indexes)-image2_crop_B(indexes);

[idx, C] = kmeans(double(feature_Vector)',k);

% Execute kMeans over RGB difference vector

for cluster_num = 1:k
    
    cluster_mask{cluster_num} = zeros(size(mask_gray));
    cluster_mask{cluster_num}(changed_pixels_ind(idx==cluster_num)) = 1;
    
    cluster_mask_size(cluster_num) = sum(cluster_mask{cluster_num},'all');
end

num_pixels = size(cluster_mask{1},1)*size(cluster_mask{1},2);

if doPlot
    figure
    for i = 1:k
        subplot(1,k,i)
        imshow(cluster_mask{i})
        title(sprintf('Cluster %d, %2.f %% of Size',...
            i,100*cluster_mask_size(i)/num_pixels));
    end
end

pic1_clusterColors = double(C(:,1:3));
pic2_clusterColors = double(C(:,4:6));

if doPlot
    figure
    for i = 1:k
        subplot(2,k,i)
        imshow(cluster_mask{i}.*image1_crop)
        
%         title(sprintf('Im1 Cl %d From Col %s',...
%             i,pic1_clusterColors{i}));
        
        
        subplot(2,k,k+i)
        imshow(cluster_mask{i}.*image2_crop)
%         title(sprintf('Im2 Cl %d To Col %s',...
%             i,pic2_clusterColors{i}));
    end
end

end