clear;
close all;
clc;

%  Load image 
img = im2double(imread('leafCoin.jpg'));

%  Recreate clean masks (Task D) 
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

% Keep largest region
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

%  Boundaries (Task F) 
leafBoundary = imdilate(cleanLeaf, se) & ~cleanLeaf;
coinBoundary = imdilate(cleanCoin, se) & ~cleanCoin;

%  Centroid calculation 
leafProps = regionprops(cleanLeaf, 'Centroid');
coinProps = regionprops(cleanCoin, 'Centroid');
leafCent = leafProps.Centroid;
coinCent = coinProps.Centroid;

% Medoid calculation (closest pixel to centroid) 
[rowLeaf, colLeaf] = find(cleanLeaf);
distLeaf = hypot(colLeaf - leafCent(1), rowLeaf - leafCent(2));
[~, idLeaf] = min(distLeaf);
leafMed = [colLeaf(idLeaf), rowLeaf(idLeaf)];

[rowCoin, colCoin] = find(cleanCoin);
distCoin = hypot(colCoin - coinCent(1), rowCoin - coinCent(2));
[~, idCoin] = min(distCoin);
coinMed = [colCoin(idCoin), rowCoin(idCoin)];

% GLI calculation (Green Leaf Index) 
R = img(:,:,1);
G = img(:,:,2);
B = img(:,:,3);

leafR = R(cleanLeaf);
leafG = G(cleanLeaf);
leafB = B(cleanLeaf);

gli = (2*leafG - leafR - leafB) ./ (2*leafG + leafR + leafB + eps);
meanGLI = mean(gli);

%  Overlay everything 
annotated = img;

% leaf boundary (red)
annotated(:,:,1) = annotated(:,:,1) + leafBoundary;
annotated(:,:,2) = annotated(:,:,2) .* ~leafBoundary;
annotated(:,:,3) = annotated(:,:,3) .* ~leafBoundary;

% coin boundary (blue)
annotated(:,:,3) = annotated(:,:,3) + coinBoundary;
annotated(:,:,1) = annotated(:,:,1) .* ~coinBoundary;
annotated(:,:,2) = annotated(:,:,2) .* ~coinBoundary;

%  Display final output 
figure;
imshow(annotated);
hold on;

% centroid markers
plot(leafCent(1), leafCent(2), 'yo', 'MarkerSize', 10, 'LineWidth', 2);
plot(coinCent(1), coinCent(2), 'co', 'MarkerSize', 10, 'LineWidth', 2);

% medoid markers
plot(leafMed(1), leafMed(2), 'y+', 'MarkerSize', 12, 'LineWidth', 2);
plot(coinMed(1), coinMed(2), 'c+', 'MarkerSize', 12, 'LineWidth', 2);

% GLI annotation
text(leafCent(1)+20, leafCent(2)-20, ...
    sprintf('GLI = %.3f', meanGLI), ...
    'Color','yellow','FontSize',12,'FontWeight','bold');

title('Output 1: Boundaries, Centroid, Medoid, and GLI Annotation');
