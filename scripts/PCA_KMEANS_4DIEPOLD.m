function [change_map] = PCA_KMEANS_4DIEPOLD(dif_image,h, progress)
% This function is responsible for detecting changes using PCA and k-Means
%
% Inputs:   dif_image:  Difference image
%           h:          Size of overlapping and nonoverlapping hxh blocks                  
%           progress:   Necessary in order to change progress value for
%                       progress bar
% Output:   change_map: Binary change map
%

%% Kmeans Flipping Problem
% This line of code is necessary to prevent k-Means from swapping changed
% pixels with unchanged pixels (flipping pixels)
dif_image(1:5,1:5) = 0; 

%% Extraction of hxh ovelapping pixel blocks
% Getting row and column size
[rows,~] = size(dif_image);
cols = rows;

% Calculate padding size for borders
padding_top_left = abs(-ceil(h/2) + 1);
padding_bottom_right = h - ceil(h/2);

% Adding zero padding to the difference image
pad_dif_im = zeros(rows + padding_top_left + padding_bottom_right, cols + padding_top_left + padding_bottom_right);
pad_dif_im(1 + padding_top_left : rows + padding_top_left, 1 + padding_top_left : cols + padding_top_left) = dif_image;

% Extracting overlapping hxh pixel blocks
pixel_vector_set = zeros(h^2, rows * cols);
count = 1;
for i = 1 : rows
    for j = 1 : cols
        pixel_block = pad_dif_im((i + padding_top_left) - ceil(h/2) + 1 : ( i + padding_top_left) + h - ceil(h/2), (j + padding_top_left) - ceil(h/2) + 1:(j + padding_top_left) + h - ceil(h/2));
        pixel_vector_set(:, count) = reshape(pixel_block', [], 1);
        count = count + 1;
    end
end
clear count;

progress.Value = 0.6;

%% Extraction of hxh nonoverlapping blocks
% Maximum amount of nonoverlapping blocks
M = floor((size(dif_image,1)*size(dif_image,2))/(h*h)); 

% Calculating padding size for borders
if mod(size(dif_image,1),h) == 0 
    padding_size_row = 0;
else
    padding_size_row = h - mod(size(dif_image,1),h);
end

if mod(size(dif_image,2),h) == 0 % 
    padding_size_col = 0;
else
    padding_size_col = h - mod(size(dif_image,2),h);
end

% Adding zero padding to the difference image
padded_dif_image = zeros(rows+padding_size_row, cols+padding_size_col); 
padded_dif_image(1:rows, 1:cols) = dif_image;

%Amount of nonoverlapping hxh blocks per row and column
blocks_per_col = size(padded_dif_image,1) / h;  
blocks_per_row = size(padded_dif_image,2) / h;  

% Extracting nonoverlapping hxh blocks
block_vector = zeros(h*h,blocks_per_col*blocks_per_row);
count = 1;
for i = 1 : blocks_per_col
    for j = 1 : blocks_per_row 
        block = padded_dif_image((i-1)*h+1:i*h,(j-1)*h+1:j*h); 
        block_vector(:,count) = reshape(block', [], 1);   
        count = count + 1;
    end      
end 

% Only M nonoverlapping hxh block needed for PCA, cutting off unnecessary
% blocks
block_vector = block_vector(:,1:M); 
clear count;

progress.Value = 0.7;

%% PCA
% Standardize vectors
mean_block_vector = mean(block_vector,2); 
difference_block_vector = block_vector - mean_block_vector; 

% Calculate Covariance matrix
covariance_matrix = zeros(size(difference_block_vector,1));

for i = 1 : size(difference_block_vector,2) 
    pre_covariance_matrix = difference_block_vector(:,i) * difference_block_vector(:,i)';
    covariance_matrix = covariance_matrix + pre_covariance_matrix;
end

covariance_matrix = covariance_matrix ./ M; 

% Calculate eigenvectors and transformation matrix
[eigenvector_matrix,~] = eig(covariance_matrix);
transformation_matrix = fliplr(eigenvector_matrix); 

% Creating feature vector space
feature_vector = transformation_matrix' * (pixel_vector_set - mean_block_vector); % Im Paper: Seite 774

progress.Value = 0.8;
progress.Message = "Almost Done...";

%% K-Means algorithm
[label,~] = kmeans(feature_vector',2);
progress.Value = 1;

% Generating change map from array 'label'
change_map = reshape(label, [rows cols])';
change_map = change_map - 1;

% These lines of code are necessary to prevent k-Means from swapping changed
% pixels with unchanged pixels (-> flipping pixels)
if change_map(1) ~= dif_image(1) 
    change_map = ~change_map;
end
end
