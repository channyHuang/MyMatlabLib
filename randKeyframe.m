function randKeyframe()
    randFrame(50);
end

function randFrame(numOfImg, imgDir, resultDir) 
if nargin < 2
    imgDir = 'E:/RealFootData/data_new/video3/picAll';
    resultDir = 'E:/RealFootData/data_new/video3/randPic';
end
imgfiles = dir([imgDir '/*.jpg']);
step = floor(length(imgfiles) / numOfImg);
i = 0;
for imgNo = 1:step:length(imgfiles)
    i = i + 1;
    img = imread([imgDir '/' imgfiles(imgNo).name]);
    imwrite(img, [resultDir '/' num2str(i, '%08d') '.jpg']);
end

end