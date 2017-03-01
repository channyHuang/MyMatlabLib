function test() 
    path = 'D:\useAsE\mycode\QtCmakeTest\build';
    Kdata = load([path '/K.txt']);
    Rdata = load([path '/R.txt']);
    tdata = load([path '/t.txt']);
    Pdata = load([path '/P.txt']);
    
    num = size(Kdata, 1) / 3;
    K = zeros(3, 3, num);
    R = zeros(3, 3, num);
    P = zeros(3,4,num);
    t = zeros(3, 1, num);
    for i = 1:num
        K(:,:,i) = Kdata(i*3-2:i*3, :);
        R(:,:,i) = Rdata(i*3-2:i*3, :);
        P(:,:,i) = Pdata(i*3-2:i*3, :);
        t(:,:,i) = tdata(i, :)';
    end
    
    poseDir = 'E:\1611_foot_data\1_mobile\f002_mobile\result_00\visualSFM.nvm.cmvs\00';
    [nK, nR, nt, sfmIndex, row, col] = readPose(poseDir);
end

%%
function [K, R, t, sfmIndex, row, col] = readPose(poseDir)
    intrincfile = [poseDir '/cameras_v2.txt'];
    fid = fopen(intrincfile);
    while 1
        buf = fgetl(fid);
        if (length(buf) <= 0 )
            continue;
        end
        if (strcmp(buf(1), '#') ~= 1)
            break;
        end 
    end
    filenum = sscanf(buf, '%d');
    
    P = zeros(3, 4, filenum);
    R = zeros(3, 3, filenum);
    t = zeros(3, 1, filenum);
    K = ones(3, 3, filenum);
    
    sfmIndex = zeros(filenum, 1);
    for i = 1:filenum
        buf = fscanf(fid, '%s', 2);
        str = strsplit(buf, '\');
        str = str{length(str)};
        orgIndex = sscanf(str, '%d.jpg');
        sfmIndex(i) = orgIndex;
        buf = fscanf(fid, '%f', 3);
        K(:, :, i) = [buf(1), 0, buf(2); 0, buf(1), buf(3); 0, 0, 1];
        
        if i == 1
            row = buf(3)*2;
            col = buf(2)*2;
        end
        
        buf = fscanf(fid, '%f', 26);
    end
    
    fclose(fid);
    
    posefiles = dir([poseDir '/txt/*.txt']);
    %filenum = length(posefiles);
    
    if (filenum ~= length(posefiles))
        fprintf('Error: num of pose files not equal to filenum value');
    end
    
    for i = 1:filenum
        posefile = [poseDir '/txt/' posefiles(i).name];
        fid = fopen(posefile, 'rt');
        buf = fscanf ( fid, '%s', 1 );
        buf = fscanf(fid, '%f');
        fclose(fid);
        
        P(:, :, i) = reshape(buf, 4, 3)';
        RT = inv(K(:, :, i))*P(:, :, i);
        R(:, :, i) = RT(1:3, 1:3);
        t(:,:,i) = RT(1:3, 4);
        
    end
end
