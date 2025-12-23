clear;
close all;
clc;

%  Recreate masks from Task C 
img = im2double(imread('leafCoin.jpg'));

hsvImg = rgb2hsv(img);
H = hsvImg(:,:,1);
S = hsvImg(:,:,2);
V = hsvImg(:,:,3);

leafMask = (H > 0.20 & H < 0.45) & (S > 0.15) & (V > 0.10);
coinMask = (H > 0.03 & H < 0.12) & (S > 0.20 & S < 0.75) & (V > 0.25);

leafMask = bwareaopen(leafMask, 800);
coinMask = bwareaopen(coinMask, 300);

%  Morphological cleaning 
se = strel('disk',5);                  % structuring element

% Leaf: close gaps, remove spikes, fill holes
cleanLeaf = imclose(leafMask, se);
cleanLeaf = imopen(cleanLeaf, se);
cleanLeaf = imfill(cleanLeaf, 'holes');

% Coin: similar but slightly less strict if needed
cleanCoin = imclose(coinMask, se);
cleanCoin = imopen(cleanCoin, se);
cleanCoin = imfill(cleanCoin, 'holes');

%  Keep only largest object in each mask 
[lLeaf, nLeaf] = bwlabel(cleanLeaf);
if nLeaf > 1
    statsLeaf = regionprops(lLeaf,'Area');
    [~, iMax] = max([statsLeaf.Area]);
    cleanLeaf = (lLeaf == iMax);
end

[lCoin, nCoin] = bwlabel(cleanCoin);
if nCoin > 1
    statsCoin = regionprops(lCoin,'Area');
    [~, iMax] = max([statsCoin.Area]);
    cleanCoin = (lCoin == iMax);
end

%  Masked colour images 
leafImg = img;
leafImg(repmat(~cleanLeaf,1,1,3)) = 0;

coinImg = img;
coinImg(repmat(~cleanCoin,1,1,3)) = 0;

bothMask = cleanLeaf | cleanCoin;
bothImg = img;
bothImg(repmat(~bothMask,1,1,3)) = 0;

%  Display results 
figure;
subplot(2,3,1), imshow(cleanLeaf), title('Clean Leaf Mask');
subplot(2,3,2), imshow(cleanCoin), title('Clean Coin Mask');
subplot(2,3,3), imshow(bothMask),  title('Union Clean Masks');

subplot(2,3,4), imshow(leafImg),  title('Leaf (Cleaned)');
subplot(2,3,5), imshow(coinImg),  title('Coin (Cleaned)');
subplot(2,3,6), imshow(bothImg),  title('Leaf + Coin (Cleaned)');
