clear; close all; clc;

%% Load image
[file, path] = uigetfile({'*.jpg;*.jpeg;*.png'});
if isequal(file,0), return; end
img = im2double(imread(fullfile(path,file)));

%% HSV + RGB
hsvImg = rgb2hsv(img);
H = hsvImg(:,:,1); S = hsvImg(:,:,2); V = hsvImg(:,:,3);
R = img(:,:,1); G = img(:,:,2); B = img(:,:,3);

%% Coin segmentation
coinMask = (H > 0.03 & H < 0.12) & (S > 0.2 & S < 0.8) & (V > 0.2);
coinMask = bwareaopen(coinMask,300);
coinMask = imclose(coinMask,strel('disk',5));
coinMask = imopen(coinMask,strel('disk',5));
coinMask = imfill(coinMask,'holes');

% keep largest coin
[Lc,nc] = bwlabel(coinMask);
if nc > 1
    s = regionprops(Lc,'Area');
    [~,m] = max([s.Area]);
    coinMask = (Lc == m);
end

%% Leaf segmentation
leafMask = (H > 0.16 & H < 0.52) & (S > 0.03) & (V > 0.15 & V < 0.95);
leafMask = bwareaopen(leafMask,800);
leafMask = imclose(leafMask,strel('disk',5));
leafMask = imopen(leafMask,strel('disk',5));
leafMask = leafMask & ~coinMask;

%% mm/pixel from coin
coinMM = 25.9;
cstat = regionprops(coinMask,'MajorAxisLength');
mmPerPixel = coinMM / cstat.MajorAxisLength;

%% Leaf measurements
[Lleaf,n] = bwlabel(leafMask);
stats = regionprops(Lleaf,'Area','Perimeter','MajorAxisLength','MinorAxisLength','Centroid','Orientation','BoundingBox');

leafArea = zeros(n,1);
leafLen  = zeros(n,1);
leafWid  = zeros(n,1);
leafGLI  = zeros(n,1);
leafDamage = zeros(n,1);
leafCrop = cell(n,1);

for k = 1:n
    mk = (Lleaf == k);

    leafArea(k) = stats(k).Area * mmPerPixel^2;
    leafLen(k)  = stats(k).MajorAxisLength * mmPerPixel;
    leafWid(k)  = stats(k).MinorAxisLength * mmPerPixel;

    r = R(mk); g = G(mk); b = B(mk);
    leafGLI(k) = mean((2*g - r - b) ./ (2*g + r + b + 1e-6));

    filled = imfill(mk,'holes');
    lost = sum(filled(:)) - sum(mk(:));
    leafDamage(k) = 100 * lost / sum(filled(:));

    leafCrop{k} = imcrop(img, stats(k).BoundingBox);
end

%% Plot graphs (GLI + Area)
figure;
subplot(1,2,1);
bar(leafArea);
title('Leaf Area Ranking'); ylabel('Area (mm^2)'); xlabel('Leaf');

subplot(1,2,2);
bar(leafGLI);
title('GLI Ranking'); ylabel('GLI'); xlabel('Leaf');

%% Boundary overlay
leafEdge = imdilate(bwperim(leafMask),strel('disk',2));
coinEdge = imdilate(bwperim(coinMask),strel('disk',2));

annot = img;
annot(:,:,1) = annot(:,:,1) + leafEdge;
annot(:,:,3) = annot(:,:,3) + coinEdge;

figure; imshow(annot); hold on;
title('Annotated Leaves');

%% Draw axes and  text
for k = 1:n
    c = stats(k).Centroid;     % leaf centre
    angle = deg2rad(stats(k).Orientation);

    L = stats(k).MajorAxisLength / 2;
    W = stats(k).MinorAxisLength / 2;

    % Vertical axis (yellow) → major axis
    vx1 = c(1) - L*cos(angle);
    vy1 = c(2) + L*sin(angle);
    vx2 = c(1) + L*cos(angle);
    vy2 = c(2) - L*sin(angle);

    plot([vx1 vx2],[vy1 vy2],'y-','LineWidth',2);

    % Horizontal axis (cyan) → minor axis
    hx1 = c(1) - W*cos(angle+pi/2);
    hy1 = c(2) + W*sin(angle+pi/2);
    hx2 = c(1) + W*cos(angle+pi/2);
    hy2 = c(2) - W*sin(angle+pi/2);

    plot([hx1 hx2],[hy1 hy2],'c-','LineWidth',2);

    % Label box
    txt = sprintf(['Leaf %d\nArea = %.1f mm^2\n' ...
                   'Length = %.1f mm\nWidth = %.1f mm\n' ...
                   'GLI = %.3f\nDamage = %.1f%%'], ...
                   k, leafArea(k), leafLen(k), leafWid(k), leafGLI(k), leafDamage(k));

    text(c(1)+10,c(2)+10,txt,'Color','w','FontSize',6,...
         'BackgroundColor',[0 0 0 0.5],'FontWeight','bold');

    plot(c(1),c(2),'r+','MarkerSize',10,'LineWidth',2);
end

%% Leaf gallery
figure;
rows = ceil(n/2); cols = 2;
for k = 1:n
    subplot(rows,cols,k);
    imshow(leafCrop{k});
    title(sprintf('Leaf %d',k));
end
