imgName = 'E:\RealFootData\data_new\video3\picAll\00000001.jpg';
method = 1;
switch method
    case 1
%Prewitt����
I = imread(imgName);
I = rgb2gray(I);
BW1 = edge(I,'prewitt',0.01);             % 0.04Ϊ�ݶ���ֵ
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
        %��ͬ��ֵ��LoG���Ӽ��ͼ��ı�Ե
I = imread(imgName);
I = rgb2gray(I);
BW1 = edge(I,'log',0.001); % ��=2
imshow(BW1);title('��=2')
BW1 = edge(I,'log',0.001,3); % ��=3
figure, imshow(BW1);title('��=3')
    case 3
        %Canny���Ӽ��ͼ��ı�Ե
I = imread(imgName);
I = rgb2gray(I);
imshow(I);
BW1 = edge(I,'canny',0.2);
figure,imshow(BW1);
    case 4
        %ͼ�����ֵ�ָ�
I=imread(imgName);
I = rgb2gray(I);
imhist(I);          % �۲�Ҷ�ֱ��ͼ�� �Ҷ�140���йȣ�ȷ����ֵT=140
I1=im2bw(I,140/255); % im2bw������Ҫ���Ҷ�ֵת����[0,1]��Χ��
figure,imshow(I1);
    case 5
        %��ˮ����ֵ���ָ�ͼ��
afm = imread(imgName);
afm = rgb2gray(afm);
figure, imshow(afm);
se = strel('disk', 15);
Itop = imtophat(afm, se); % ��ñ�任
Ibot = imbothat(afm, se); % ��ñ�任
figure, imshow(Itop, []);   % ��ñ�任������ԭʼͼ��ĻҶȷ�ֵ
figure, imshow(Ibot, []);   % ��ñ�任������ԭʼͼ��ĻҶȹ�ֵ
Ienhance = imsubtract(imadd(Itop, afm), Ibot);% ��ñͼ�����ñͼ���������ǿͼ��
figure, imshow(Ienhance);
Iec = imcomplement(Ienhance); % ��һ����ǿͼ��
Iemin = imextendedmin(Iec, 20); figure,imshow(Iemin) % ����Iec�еĹ�ֵ
Iimpose = imimposemin(Iec, Iemin);
wat = watershed(Iimpose); % ��ˮ��ָ�
rgb = label2rgb(wat); figure, imshow(rgb); % �ò�ͬ����ɫ��ʾ�ָ���Ĳ�ͬ����
    case 6
        %�Ծ�������Ĳ����ֽ�
        
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
        %��ͼ���Ϊ���ֺͷ����ֵ��������
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
%ŷʽ����
d1(j,i)=sqrt((myI(j,i,1)-180)^2+(myI(j,i,2)-180)^2+(myI(j,i,3)-180)^2);
d2(j,i)=sqrt((myI(j,i,1)-200)^2+(myI(j,i,2)-200)^2+(myI(j,i,3)-200)^2);
       
        if (d1(j,i)>=d2(j,i))
             I0(j,i)=1;
        end
    end
end
figure(1);
imshow(I);
% ��ʾRGB�ռ�ĻҶ�ֱ��ͼ��ȷ��������������(180,180,180)��(200,200,200)
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
        %��̬ѧ�ݶȼ���ֵͼ��ı�Ե
  I=imread(imgName);
I = rgb2gray(I);
imshow(I);
I=~I;        % ��ʴ����ԻҶ�ֵΪ1�Ľ���
figure, imshow(I);
SE=strel('square',3); % ����3��3��ʴ�ṹԪ��
J=imerode(~I,SE);
BW=(~I)-J;        % ����Ե
figure,imshow(BW);
    case 9
%��̬ѧʵ��������PCBͼ����ɾ�����е����ߣ�������оƬ����
  I=imread(imgName);
I = rgb2gray(I);
imshow(I);
SE=strel('rectangle',[40 30]); % �ṹ����
J=imopen(I,SE);            % ��������
figure,imshow(J);


end


if 0
clc; clear all; close all;
I = imread(imgName); % ����ͼ��
figure; 
subplot(1, 3, 1); imshow(I); title('ԭͼ��', 'FontWeight', 'Bold');
I1 = rgb2hsv(I); % RGBת����HSV�ռ�
h = I1(:, :, 2); % S��
bw = im2bw(h, graythresh(h)); % ��ֵ��
bw = ~bw; % ȡ��
bw1 = imfill(bw, 'holes'); % ����
bw1 = imopen(bw1, strel('disk', 5)); % ͼ�񿪲���
bw1 = bwareaopen(bw1, 2000); % ����˲�
subplot(1, 3, 2); imshow(bw1); title('��ֵͼ��', 'FontWeight', 'Bold');
bw2 = cat(3, bw1, bw1, bw1); % ����ģ��
I2 = I .* uint8(bw2); % ���
subplot(1, 3, 3); imshow(I2); title('�ָ�ͼ��', 'FontWeight', 'Bold');

end