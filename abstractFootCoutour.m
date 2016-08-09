%%
% A4, foot, frames
% input: image dir, result dir
% output£ºcontous in result dir
function abstractFootCoutour(imgDir, maskDir)
if nargin < 2
    imgDir = 'E:/RealFootData/data_new/video3/picAll';
    maskDir = 'E:/RealFootData/data_new/video3/maskAut';
end

imgfiles = dir([imgDir '/*.jpg']);
for imgNo = 1:length(imgfiles)
    abstractSingleImage([imgDir '/' imgfiles(imgNo).name], [maskDir '/' num2str(imgNo, '%08d') '.jpg']);
end
end

function abstractSingleImage(imgName, outputName)
%original image
img = imread(imgName);

%change to binary image to abstract A4 paper area
I = imread(imgName);
I = im2bw(I, graythresh(I));

se = strel('disk',6);
I = imerode(I, se);
I = imfill(I, 'holes');

%drawConvexHull(I);
    stats = regionprops(I, 'ConvexHull', 'FilledArea');
    pos = 1;
    for i = 1:length(stats)
        if stats(i).FilledArea >  stats(pos).FilledArea
            pos = i;
        end
    end
    stats = stats(pos);
    iptsetpref('ImshowBorder','tight');
    set(0,'DefaultFigureMenu','none');
    format compact;

    set(gca,'position',[0 0 1 1])
    imshow(I,'InitialMagnification','fit');
    hold on;
    plot(stats.ConvexHull(:,1), stats.ConvexHull(:,2));
    h = fill(stats.ConvexHull(:,1), stats.ConvexHull(:,2), 'w');
    hold off;

    set (gcf,'Position',[0,0,512,512]);
    axis normal;
    saveas(gca, 'mask', 'jpg');
    close all;

mask = imread('mask.jpg');    
[I, mask] = showOriginWithMask(img, mask);
I = rgb2gray(I);
I(I > 150) = 0;
I(I < 75) = 0;
if 1
    I(I > 0) = 255;
    stats = regionprops(im2bw(I), 'ConvexHull', 'FilledArea');
    pos = 1;
    for i = 1:length(stats)
        if stats(i).FilledArea >  stats(pos).FilledArea
            pos = i;
        end
    end
    stats = stats(pos);
    iptsetpref('ImshowBorder','tight');
    set(0,'DefaultFigureMenu','none');
    format compact;

    set(gca,'position',[0 0 1 1])
    imshow(uint8(zeros(size(I, 1), size(I, 2))),'InitialMagnification','fit');
    hold on;
    plot(stats.ConvexHull(:,1), stats.ConvexHull(:,2));
    h = fill(stats.ConvexHull(:,1), stats.ConvexHull(:,2), 'w');
    hold off;

    set (gcf,'Position',[0,0,512,512]);
    axis normal;
    saveas(gca, 'mask', 'jpg');
    close all;
    
    Contour1 = imread('mask.jpg');
else 
BW1 = edge(I,'prewitt',0.04);

se = strel('disk',6);
nBW = imerode(I, se);
se = strel('disk',12);
nBW = imdilate(nBW, se);
nBW = imfill(nBW, 'hole');
figure, imshow(nBW); %paper inside
Contour1 = nBW;
Contour1(Contour1 ~= 0) = 255;
end

%outside
nI = double(rgb2gray(img)).*(1-mask);
nI = uint8(nI);
BW1 = edge(nI, 'canny', 0.03);
nBW = imdilate(BW1, se);
nBW = imfill(nBW, 'hole');
nBW = imfill(~nBW, 'hole');

%drawConvexHull(nBW);
close all
I = nBW;
stats = regionprops(I, 'ConvexHull', 'FilledArea');
pos = 1;
for i = 1:length(stats)
    if stats(i).FilledArea >  stats(pos).FilledArea
        pos = i;
    end
end
stats = stats(pos);

iptsetpref('ImshowBorder','tight');
set(0,'DefaultFigureMenu','none');
format compact;

set(gca,'position',[0 0 1 1]);
figure, imshow(Contour1,'InitialMagnification','fit');
hold on;
plot(stats.ConvexHull(:,1), stats.ConvexHull(:,2));
h = fill(stats.ConvexHull(:,1), stats.ConvexHull(:,2), 'w');
hold off;

set (gcf,'Position',[0,0,512,512]);
axis normal;
saveas(gca, 'mask', 'jpg');
%final mask
mask = imread('mask.jpg');
showOriginWithMask(img, mask);

close all;
mask = im2bw(mask);
imshow(mask);

se = strel('disk',25);
mask = imdilate(mask, se);
mask = imfill(mask, 'hole');

imwrite(mask, 'mask.jpg');

mask = imread('mask.jpg');
[I, mask] = showOriginWithMask(img, mask);
mask_mat = mask * 255;
%final mask 2
mask = imerode(mask, se);
mask = imerode(mask, se);
showOriginWithMask(img, mask);
%imwrite(mask, 'mask.jpg');

mask_mat(mask == 0 & mask_mat == 255) = 125;
mask_mat = uint8(mask_mat);
%imshow(mask_mat);

stats = regionprops(im2bw(mask_mat), 'ConvexHull', 'FilledArea');
if length(stats) > 1
    mask = Contour1;
    mask_mat = imerode(mask, se);
    mask = imdilate(mask, se);
    mast_mat(mask == 255 & mask_mat == 0) = 125;
end

close all;
imwrite(mask_mat, outputName);
end

function [I, mask] = showOriginWithMask(img, mask)
    mask = imresize(im2bw(mask), [size(img,1), size(img,2)]);
    mask = double(mask);
    I = img;
    I = double(I);
    I(:,:,1) = I(:,:,1) .* mask;
    I(:,:,2) = I(:,:,2) .* mask;
    I(:,:,3) = I(:,:,3) .* mask;
    I = uint8(I);
    imshow(I);
end

function drawConvexHull(I)
stats = regionprops(I, 'ConvexHull', 'FilledArea');
pos = 1;
for i = 1:length(stats)
    if size(stats(i).ConvexHull, 1) >  size(stats(pos).ConvexHull, 1)
        pos = i;
    end
end
stats = stats(i);
iptsetpref('ImshowBorder','tight');
set(0,'DefaultFigureMenu','none');
format compact;

set(gca,'position',[0 0 1 1])
figure, imshow(I,'InitialMagnification','fit');
hold on;
plot(stats.ConvexHull(:,1), stats.ConvexHull(:,2));
h = fill(stats.ConvexHull(:,1), stats.ConvexHull(:,2), 'r');
hold off;
end