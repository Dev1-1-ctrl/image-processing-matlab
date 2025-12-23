clear;
close all;
clc;

% Load image and recreate clean masks (same as Task D) 
img = im2double(imread('leafCoin.jpg'));

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

% Keep single object only
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

% Entry-wise product images (Task wants these as Input 1 and Input 2) 
leafImg = img;
leafImg(repmat(~cleanLeaf,1,1,3)) = 0;

coinImg = img;
coinImg(repmat(~cleanCoin,1,1,3)) = 0;

% Display required inputs
figure;
subplot(1,2,1), imshow(leafImg), title('Input 1: Entry-wise Product (Leaf Only)');
subplot(1,2,2), imshow(coinImg), title('Input 2: Entry-wise Product (Coin Only)');

% Extract RGB channels 
R = img(:,:,1);
G = img(:,:,2);
B = img(:,:,3);

%  Histogram settings
edges = linspace(0,1,257); 
centres = (edges(1:end-1)+edges(2:end))/2;
x255 = centres * 255;

%  Leaf histograms 
leafR = R(cleanLeaf);
leafG = G(cleanLeaf);
leafB = B(cleanLeaf);

hR = histcounts(leafR, edges, 'Normalization','probability');
hG = histcounts(leafG, edges, 'Normalization','probability');
hB = histcounts(leafB, edges, 'Normalization','probability');

figure;
plot(x255,hR,'r'); hold on;
plot(x255,hG,'g');
plot(x255,hB,'b');
xlabel('Intensity (0–255)');
ylabel('Normalised Frequency');
title('Output 1: Normalised RGB Histogram for Leaf');
xlim([0 255]);

%  Coin histograms 
coinR = R(cleanCoin);
coinG = G(cleanCoin);
coinB = B(cleanCoin);

hR = histcounts(coinR, edges, 'Normalization','probability');
hG = histcounts(coinG, edges, 'Normalization','probability');
hB = histcounts(coinB, edges, 'Normalization','probability');

figure;
plot(x255,hR,'r'); hold on;
plot(x255,hG,'g');
plot(x255,hB,'b');
xlabel('Intensity (0–255)');
ylabel('Normalised Frequency');
title('Output 2: Normalised RGB Histogram for Coin');
xlim([0 255]);
