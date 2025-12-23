

clear;
close all;
clc;

%  Load image 
img = im2double(imread('leafCoin.jpg'));

%  Recreate clean masks (Task D logic) 
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

% Keep only largest region
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

%  Coin measurement to derive scale mm/pixel 
coinStats = regionprops(cleanCoin, 'MajorAxisLength');
coinDiameterPixels = coinStats.MajorAxisLength;

coinDiameterMm = 25.9;  
mmPerPixel = coinDiameterMm / coinDiameterPixels;

% leaf morphometric properties
leafStats = regionprops(cleanLeaf, 'MajorAxisLength','MinorAxisLength',...
                                      'Area','Perimeter','BoundingBox');

leafMajorMm = leafStats.MajorAxisLength * mmPerPixel;
leafMinorMm = leafStats.MinorAxisLength * mmPerPixel;
leafAreaMm2 = leafStats.Area * (mmPerPixel^2);
leafPerimeterMm = leafStats.Perimeter * mmPerPixel;

% Draw major/minor axes (bounding box method) 
box = leafStats.BoundingBox; % [x y w h]
cx = box(1) + box(3)/2;
cy = box(2) + box(4)/2;

% horizontal length (minor)
x1 = cx - box(3)/2;
x2 = cx + box(3)/2;

% vertical length (major)
y1 = cy - box(4)/2;
y2 = cy + box(4)/2;

annotated = img;

% Overlay boundaries (from Task F) for clarity 
leafBoundary = imdilate(cleanLeaf, se) & ~cleanLeaf;

annotated(:,:,1) = annotated(:,:,1) + leafBoundary;
annotated(:,:,2) = annotated(:,:,2) .* ~leafBoundary;
annotated(:,:,3) = annotated(:,:,3) .* ~leafBoundary;

%  Display final image
figure;
imshow(annotated);
hold on;

% major axis (vertical)
line([cx cx], [y1 y2], 'Color','yellow','LineWidth',2);

% minor axis (horizontal)
line([x1 x2], [cy cy], 'Color','cyan','LineWidth',2);

%  text is placed to rightside 
[xLeaf, yLeaf] = find(cleanLeaf);
minX = min(xLeaf);
maxX = max(xLeaf);
minY = min(yLeaf);
maxY = max(yLeaf);

% Move text well to the right (80 px spacing)
textX = maxY + 80;   % horizontal position
textY = minX + 20;   % vertical start

lineSpacing = 80;    % spacing between text lines

% Black text 
text(textX, textY, sprintf('Length = %.2f mm', leafMajorMm), ...
     'Color','black','FontSize',12);

text(textX, textY + lineSpacing, sprintf('Width = %.2f mm', leafMinorMm), ...
     'Color','black','FontSize',12);

text(textX, textY + 2*lineSpacing, sprintf('Area = %.2f mm^2', leafAreaMm2), ...
     'Color','black','FontSize',12);

text(textX, textY + 3*lineSpacing, sprintf('Perimeter = %.2f mm', leafPerimeterMm), ...
     'Color','black','FontSize',12);
