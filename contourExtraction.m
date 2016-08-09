imgName = 'E:\RealFootData\data_new\video3\picAll\00000001.jpg';
method = 1;
switch method
    case 1
%Prewitt算子
I = imread(imgName);
I = rgb2gray(I);
BW1 = edge(I,'prewitt',0.01);             % 0.04为梯度阈值
figure(1);
imshow(I);
figure(2);
figure, imshow(BW1);

se = strel('disk',22);
%nBW = imerode(BW1, se);
nBW = imdilate(BW1, se);
nnBW = imerode(~nBW, se);
figure, imshow(nnBW);
    case 2
        %不同σ值的LoG算子检测图像的边缘
I = imread(imgName);
I = rgb2gray(I);
BW1 = edge(I,'log',0.001); % σ=2
imshow(BW1);title('σ=2')
BW1 = edge(I,'log',0.001,3); % σ=3
figure, imshow(BW1);title('σ=3')
    case 3
        %Canny算子检测图像的边缘
I = imread(imgName);
I = rgb2gray(I);
imshow(I);
BW1 = edge(I,'canny',0.2);
figure,imshow(BW1);
    case 4
        %图像的阈值分割
I=imread(imgName);
I = rgb2gray(I);
imhist(I);          % 观察灰度直方图， 灰度140处有谷，确定阈值T=140
I1=im2bw(I,140/255); % im2bw函数需要将灰度值转换到[0,1]范围内
figure,imshow(I1);
    case 5
        %用水线阈值法分割图像
afm = imread(imgName);
afm = rgb2gray(afm);
figure, imshow(afm);
se = strel('disk', 15);
Itop = imtophat(afm, se); % 高帽变换
Ibot = imbothat(afm, se); % 低帽变换
figure, imshow(Itop, []);   % 高帽变换，体现原始图像的灰度峰值
figure, imshow(Ibot, []);   % 低帽变换，体现原始图像的灰度谷值
Ienhance = imsubtract(imadd(Itop, afm), Ibot);% 高帽图像与低帽图像相减，增强图像
figure, imshow(Ienhance);
Iec = imcomplement(Ienhance); % 进一步增强图像
Iemin = imextendedmin(Iec, 20); figure,imshow(Iemin) % 搜索Iec中的谷值
Iimpose = imimposemin(Iec, Iemin);
wat = watershed(Iimpose); % 分水岭分割
rgb = label2rgb(wat); figure, imshow(rgb); % 用不同的颜色表示分割出的不同区域
    case 6
        %对矩阵进行四叉树分解
        
        I = [ 1     1     1     1     2     3     6     6
         1     1     2     1     4     5     6     8
         1     1     1     1    10    15     7     7
         1     1     1     1    20    25     7     7
        20    22    20    22     1     2     3     4
        20    22    22    20     5     6     7     8
        20    22    20    20     9    10    11    12
        22    22    20    20    13    14    15    16];
  
S = qtdecomp(I,5);
full(S)
    case 7
        %将图像分为文字和非文字的两个类别
  I=imread(imgName);

I1=I(:,:,1);
I2=I(:,:,2);
I3=I(:,:,3);
[y,x,z]=size(I);
d1=zeros(y,x);
d2=d1;
myI=double(I);
I0=zeros(y,x);
for i=1:x
    for j=1:y
%欧式聚类
d1(j,i)=sqrt((myI(j,i,1)-180)^2+(myI(j,i,2)-180)^2+(myI(j,i,3)-180)^2);
d2(j,i)=sqrt((myI(j,i,1)-200)^2+(myI(j,i,2)-200)^2+(myI(j,i,3)-200)^2);
       
        if (d1(j,i)>=d2(j,i))
             I0(j,i)=1;
        end
    end
end
figure(1);
imshow(I);
% 显示RGB空间的灰度直方图，确定两个聚类中心(180,180,180)和(200,200,200)
figure(2);    
subplot(1,3,1);
imhist(I1);
subplot(1,3,2);
imhist(I2);
subplot(1,3,3);
imhist(I3);
figure(4);
imshow(I0);
    case 8
        %形态学梯度检测二值图像的边缘
  I=imread(imgName);
I = rgb2gray(I);
imshow(I);
I=~I;        % 腐蚀运算对灰度值为1的进行
figure, imshow(I);
SE=strel('square',3); % 定义3×3腐蚀结构元素
J=imerode(~I,SE);
BW=(~I)-J;        % 检测边缘
figure,imshow(BW);
    case 9
%形态学实例——从PCB图像中删除所有电流线，仅保留芯片对象
  I=imread(imgName);
I = rgb2gray(I);
imshow(I);
SE=strel('rectangle',[40 30]); % 结构定义
J=imopen(I,SE);            % 开启运算
figure,imshow(J);


end


if 0
clc; clear all; close all;
I = imread(imgName); % 载入图像
figure; 
subplot(1, 3, 1); imshow(I); title('原图像', 'FontWeight', 'Bold');
I1 = rgb2hsv(I); % RGB转换到HSV空间
h = I1(:, :, 2); % S层
bw = im2bw(h, graythresh(h)); % 二值化
bw = ~bw; % 取反
bw1 = imfill(bw, 'holes'); % 补洞
bw1 = imopen(bw1, strel('disk', 5)); % 图像开操作
bw1 = bwareaopen(bw1, 2000); % 面积滤波
subplot(1, 3, 2); imshow(bw1); title('二值图像', 'FontWeight', 'Bold');
bw2 = cat(3, bw1, bw1, bw1); % 构造模板
I2 = I .* uint8(bw2); % 点乘
subplot(1, 3, 3); imshow(I2); title('分割图像', 'FontWeight', 'Bold');

end