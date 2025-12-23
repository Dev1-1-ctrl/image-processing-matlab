    clear;
    close all;
    clc;

    img = im2double(imread('leafCoin.jpg'));   % load image 

    hsvImg = rgb2hsv(img);        % convert to HSV
    H = hsvImg(:,:,1);
    S = hsvImg(:,:,2);
    V = hsvImg(:,:,3);

    % Leaf threshold
    leafMask = (H > 0.20 & H < 0.45) & (S > 0.15) & (V > 0.10);

    % Coin threshold
    coinMask = (H > 0.03 & H < 0.12) & (S > 0.20 & S < 0.75) & (V > 0.25);

    % Remove noise
    leafMask = bwareaopen(leafMask, 800);
    coinMask = bwareaopen(coinMask, 300);

    combinedMask = leafMask | coinMask;

    maskedImg = img;
    maskedImg(repmat(~combinedMask,1,1,3)) = 0;

    figure;
    subplot(2,2,1), imshow(img),        title('Input');
    subplot(2,2,2), imshow(leafMask),   title('Leaf Mask');
    subplot(2,2,3), imshow(coinMask),   title('Coin Mask');
    subplot(2,2,4), imshow(maskedImg),  title('Masked Image');


