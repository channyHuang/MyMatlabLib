%%
function [points3d, rgb3d, imgFeature] = readNVMfile(nvmFileName)
    if nargin < 1
        nvmFileName = 'E:/RealFootData/data_new/video3/visualSFMResult/visualSFM.nvm';
    end
    [points3d, rgb3d, imgFeature] = readFile(nvmFileName);
    %scatter3(points3d(1,:), points3d(2, :), points3d(3, :), 'marker', '.', 'cdata', rgb3d');  
end
%%
function [points3d, rgb3d, imgFeature] = readFile(filename)
    fin = fopen(filename, 'r');
    if fin < 0
        errordlg('Model file can not be opened!', 'Input');
        return;
    end
    line = fgetl(fin);
    line = fgetl(fin);
    line = fgetl(fin);
    numOfImage = sscanf(line, '%d');
    for i = 1:numOfImage
        line = fgetl(fin);
    end
    
    line = fgetl(fin);
    line = fgetl(fin);
    numOfPoints = sscanf(line, '%d');
    points3d = zeros(3, numOfPoints);
    rgb3d = zeros(3, numOfPoints);
    %imgFeature = cell(numOfImage, 3); %for every image, the 3d point index that in this image
    imgFeature = cell(numOfPoints, 1);
    for i = 1:numOfPoints
        line = fgetl(fin);
        data = regexp(line, ' ', 'split');
        len = length(data);
        numdata = zeros(1, len);
        for j = 1:len
            numdata(j) = str2double(data{j});         
        end
        points3d(:, i) = numdata(1:3)';
        rgb3d(:, i) = numdata(4:6)';
        %numOfMeasure = numdata(7);
        %for j = 1:numOfMeasure
            %imgIndex = numdata(8+(j - 1)*4) + 1;
            %feaIndex = numdata(9 + (j-1)*4);
            %imgFeature{imgIndex, 1} = [imgFeature{imgIndex, 1}, i]; % 3d point index
            %imgFeature{imgIndex, 2} = [imgFeature{imgIndex, 2}, feaIndex]; %feature index
        %end
        imgFeature{i, 1} = numdata(7:end);
    end
    fclose(fin);
end