function [org_diff_im,diff_im_norm,diff_im_spaxx] = QuadModell(image1, image2, filter_size,text)
tic
if(text)
    disp("++++++++ Begin ++++++++");
    disp("-------- Preprocessing --------");
end

a= size(image1);
b = size(image2);




if((a(1)~=b(1))| (a(2)~=b(2)))
    error("Bilder haben Unterschiedliche Dimension");
end

%rechteckige zu quadratische bilder wandeln

if(a(1)~=a(2))
    [maximum,index] = max([a(1),a(2)]);
    minimum = min([a(1),a(2)]);

    image1quad = 255*ones(maximum);
    image2quad = 255*ones(maximum);
    if(index==1)
        image1quad(1:maximum,1:minimum,1) = image1;
        image2quad(1:maximum,1:minimum,1) = image2;

    elseif(index==2)
        image1quad(1:minimum,1:maximum,1) = image1;
        image2quad(1:minimum,1:maximum,1) = image2;
    end
    if(text)
        fprintf("Image size %dx%d Pixel.\n", maximum,maximum);
    end

else
    image1quad = image1;
    image2quad = image2;

end

%statistiken
prepro_time = toc;

if(text)
    fprintf("The prepatation took %d seconds.\n",prepro_time);
end 

tic

%[rows,~] = size(image1quad);


%difference image berechnen
if(text)
    disp("-------- Difference Image --------");
end
difference_image = abs(double(image1quad - image2quad));
org_diff_im =difference_image;


% Create quadratic Modell of the blocks (according to lecture's algo)
tic
cell_side_size = filter_size;

%calculate inv(A'*A)*A'    
[X, Y] = meshgrid(1:cell_side_size);
x = X(:);
y = Y(:);

A = [x.^2 y.^2 x.*y x y ones(size(x))];

lsg_precalced = inv(transpose(A)*A)*transpose(A);

if size(image1quad,1)/cell_side_size ~= ceil(size(image1quad,1)/cell_side_size)
    image1quadcellp = zeros(ceil(size(image1quad,1)/cell_side_size)*cell_side_size,ceil(size(image1quad,1)/cell_side_size)*cell_side_size);
    image2quadcellp = zeros(ceil(size(image1quad,1)/cell_side_size)*cell_side_size,ceil(size(image1quad,1)/cell_side_size)*cell_side_size);
    image1quadcellp(1:size(image1quad,1),1:size(image1quad,1)) = image1quad;
    image2quadcellp(1:size(image1quad,1),1:size(image1quad,1)) = image2quad;
else
    image1quadcellp = image1quad;
    image2quadcellp = image2quad;
end

%separate image into blocks
create_vect = cell_side_size*ones(1,size(image1quadcellp,1)/cell_side_size);

image1_cells = mat2cell(image1quadcellp,create_vect,create_vect);
image2_cells = mat2cell(image2quadcellp,create_vect,create_vect);

image_cell_size_a = size(image1_cells,1);
image_cell_size_b = size(image1_cells,2);

image1_cells = reshape(image1_cells,[],1);
image2_cells = reshape(image2_cells,[],1);

for k=1:size(image1_cells,1)
    image1_cells{k} = reshape(image1_cells{k},[],1);
    image1_cells{k} = lsg_precalced*image1_cells{k};
    image2_cells{k} = reshape(image2_cells{k},[],1);
    image2_cells{k} = lsg_precalced*image2_cells{k};
end

diff_im_vl = cellfun(@minus,image1_cells,image2_cells,'Un',0);
%calc each cells quadratic norm

diff_im_norm = cellfun(@norm,diff_im_vl);

diff_im_norm = reshape(diff_im_norm,image_cell_size_a,image_cell_size_b);
diff_im_spaxx = diff_im_norm;
diff_im_norm = imresize(diff_im_norm,cell_side_size);
if size(diff_im_norm,1) - size(image1quad,1) ~= 0
       diff_im_norm = diff_im_norm(1:size(image1quad,1),1:size(image2quad,1));
end

%elementwise multiplication of difference image and filter
diff_im_norm = difference_image.*diff_im_norm;
if(text)
    preptime = toc;
    fprintf('++The preparation took %d seconds++ \n',preptime);
end
end

