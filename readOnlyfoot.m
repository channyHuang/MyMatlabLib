

%%
function readOnlyfoot(scenePathName, modelName, poseName, maskDir)
    
    scenePathName = 'E:/1611_foot_data/1_mobile/f002_mobile/result_00';
    modelDir = 'visualSFM.nvm.cmvs/00/models/';
    modelList = dir([scenePathName '/' modelDir '*.ply']);
    modelName = [modelDir modelList(length(modelList)).name];
    %modelName = 'visualSFM.0.ply';
    poseDir = [scenePathName '/visualSFM.nvm.cmvs/00'];
    %[scene.node_xyz, scene.node_rgb, ~] = readNVMfile([scenePathName '/' sceneName]);
    
    model = Model([scenePathName '/' modelName]); 
    model.readModel();
    scene = model;

    
    [K, R, t, sfmIndex, row, col] = readPose(poseDir);

    filelist = dir([scenePathName '/mask/*.jpg']);
    %maskIndex = [0, 50, 100, 150, 200, 250, 300];%, 350];
    %for imgIndex = maskIndex
    %for i = 1:length(filelist)
    for i = 1:length(filelist)
        %maskImgName = [scenePathName '/../mask/' num2str(imgIndex, '%08d') '.jpg'];
        
        imgIndex = sscanf(filelist(i).name, '%d.jpg');
        maskImgName = [scenePathName '/mask/' filelist(i).name];
        
        maskImg = imread(maskImgName);
        if size(maskImg, 3) == 3
            maskImg = rgb2gray(maskImg);
        end
        %figure,imshow(maskImg);
        %se = strel('disk',22);
        %maskImg = imdilate(maskImg, se);
        %figure,imshow(maskImg);
        
        framenum = find(sfmIndex == imgIndex);%floor(framenum);
        if size(framenum, 1) == 0
            fprintf(['Miss frame ' num2str(imgIndex)]);
            continue;
        end
        node_xy = K(:,:,framenum)*[R(:,:,framenum), t(:,:,framenum)]* [scene.node_xyz; ones(1, size(scene.node_xyz, 2))];
        node_xy(1, :) = node_xy(1, :) ./ node_xy(3, :);
        node_xy(2, :) = node_xy(2, :) ./ node_xy(3, :);
        node_xy = node_xy(1:2,:);
        idx1 = node_xy(1, :) >= 1 & node_xy(1, :) < col + 1;
        idx2 = node_xy(2, :) >= 1 & node_xy(2, :) < row + 1;
        idx = idx1 & idx2;
        for i = 1:size(idx, 2)
            if idx(i) == 0
                continue;
            elseif maskImg(floor(node_xy(2, i)), floor(node_xy(1, i))) == 0
                idx(i) = 0;
            end
        end
        scene.node_xyz = scene.node_xyz(:, idx);
        scene.node_rgb = scene.node_rgb(:, idx);
    
    end
    writePly(scene, [scenePathName, '/pmvs_onlyfoot.ply']);
end

%%
function test() 
    addpath(genpath('D:/useAsE/matlabCode/Library/matlabmesh'));
    addpath('D:/useAsE/matlabCode/myMatlabLib');
    addpath(genpath('D:/useAsE/matlabCode/Library/gptoolbox-master'));

    readVisualSFMOnlyfoot();
    if 0
    pathName = 'D:/testModel/';
    modelName = 'pmvs_onlyfoot.ply';
    
    model = Model([pathName modelName]);
    model.readModel();
    
    [newNode, newNormal, normal] = addBottom(model.node_xyz);
    model.node_xyz = [model.node_xyz, newNode];
    model.normal = normal;
    
    hall = Model([pathName 'convexHall.ply']);
    hall.readModel();
    dist = zeros(size(model.node_xyz, 2), size(hall.node_xyz, 2));
    for i = 1:size(hall.node_xyz, 2)
        dist(:, i) = sum((model.node_xyz - repmat(hall.node_xyz(:, i), 1, size(model.node_xyz, 2))).^2, 1)';
    end
    for i = 1:size(model.node_xyz, 2) / 2
        [minn, idx] = min(dist(i, :));
        refNormal = model.node_xyz(:, i) - hall.node_xyz(:, idx);
        if sum(model.normal(:, i) .* refNormal) > 0
            model.normal(:,i) = -model.normal(:,i);
        end
    end
    model.writePly('plan3.ply');
    end
end

function [newNode, newNormal, normal] = addBottom(node_xyz)
    maxny = max(node_xyz(2, :));
    newNode = [node_xyz(1, :); zeros(1, size(node_xyz, 2)) + maxny; node_xyz(3, :)];
    newNormal = repmat([0,1,0]', 1, size(node_xyz, 2));
    
    normal = [zeros(size(node_xyz)), newNormal];
    
    k = 10;
    totalNode = [node_xyz, newNode];
    neighbors = transpose(knnsearch(transpose(totalNode), transpose(node_xyz), 'k', k+1));
    n = zeros(size(node_xyz));
    for i = 1:size(node_xyz, 2)
        x = totalNode(:, neighbors(2:end, i));
        p_bar = 1/k * sum(x, 2);
        
        P = (x - repmat(p_bar,1,k)) * transpose(x - repmat(p_bar,1,k)); %spd matrix P
        %P = 2*cov(x);
    
        [V,D] = eig(P);
    
        [~, idx] = min(diag(D)); % choses the smallest eigenvalue
        
        n(:,i) = V(:,idx);   % returns the corresponding eigenvector   
        
        normal(:,i) = V(:,idx);
        y = neighbors((neighbors(:,i) > size(node_xyz, 2)), i);
        if size(y) ~= 0
            if sum(n(:,i) .* normal(:, y(1))) < 0
%                normal(:,i) = -normal(:,i);
            end
        end
    end
    
    
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
