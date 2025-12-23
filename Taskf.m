
clear;
close all;
clc;

% Load image 
img = im2double(imread('leafCoin.jpg'));

% Recreate clean masks (same as Task D) 
hsvImg = rgb2hsv(img);
H = hsvImg(:,:,1);
S = hsvImg(:,:,2);
V = hsvImg(:,:,3);

leafMask = (H > 0.20 & H < 0.45) & (S > 0.15) & (V > 0.10);
coinMask = (H > 0.03 & H < 0.12) & (S > 0.20 & S < 0.75) & (V > 0.25);

leafMask = bwareaopen(leafMask, 800);
coinMask = bwareaopen(coinMask, 300);

se = strel('disk',5);

cleanLeaf = imclose(leafMask, se);
cleanLeaf = imopen(cleanLeaf, se);
cleanLeaf = imfill(cleanLeaf,'holes');

cleanCoin = imclose(coinMask, se);
cleanCoin = imopen(cleanCoin, se);
cleanCoin = imfill(cleanCoin,'holes');

% Keep single largest region
[Lleaf, n1] = bwlabel(cleanLeaf);
if n1 > 1
    stats = regionprops(Lleaf,'Area');
    [~, idx] = max([stats.Area]);
    cleanLeaf = (Lleaf == idx);
end

[Lcoin, n2] = bwlabel(cleanCoin);
if n2 > 1
    stats = regionprops(Lcoin,'Area');
    [~, idx] = max([stats.Area]);
    cleanCoin = (Lcoin == idx);
end

%  Morphological gradient (boundaries) 
leafBoundary = imdilate(cleanLeaf, se) & ~cleanLeaf;
coinBoundary = imdilate(cleanCoin, se) & ~cleanCoin;

%  Annotate boundaries on original image 
annotated = img;

% leaf boundary in red
annotated(:,:,1) = annotated(:,:,1) + leafBoundary;
annotated(:,:,2) = annotated(:,:,2) .* ~leafBoundary;
annotated(:,:,3) = annotated(:,:,3) .* ~leafBoundary;

% coin boundary in blue
annotated(:,:,3) = annotated(:,:,3) + coinBoundary;
annotated(:,:,1) = annotated(:,:,1) .* ~coinBoundary;
annotated(:,:,2) = annotated(:,:,2) .* ~coinBoundary;

% Display required outputs 
figure;

subplot(1,3,1);
imshow(leafBoundary);
title('Output 1: Boundary around Cleaned Leaf Binary Mask');

subplot(1,3,2);
imshow(coinBoundary);
title('Output 2: Boundary around Cleaned Coin Binary Mask');

subplot(1,3,3);
imshow(annotated);
title('Output 3: Input Image with Overlaid Object Boundaries');
