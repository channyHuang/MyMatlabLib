function readOnlyfoot_shoe(scenePath, modelName)
    scenePath = 'E:\ArtShoe2_reconstruction\code\data\m004_dc_right\data';
    modelName = 'points_all_1_o.ply';

    model = Model([scenePath '/' modelName]); 
    model.readModel();
    [K, R, t] = readPose(scenePath);
    
    filelist = dir([scenePath '/mask/*.bmp']);
    for i = 1:length(filelist)
        maskImg = imread([scenePath '/mask/' filelist(i).name]);
        row = size(maskImg, 1);
        col = size(maskImg, 2);
        if (size(maskImg, 3) ~= 1)
            maskImg = rgb2gray(maskImg);
        end
        node_xy = K(:,:,i) *[R(:,:,i), t(:,:,i)]*[model.node_xyz; ones(1, size(model.node_xyz, 2))];
        node_xy(1, :) = node_xy(1, :) ./ node_xy(3, :);
        node_xy(2, :) = node_xy(2, :) ./ node_xy(3, :);
        node_xy = node_xy(1:2,:);
        idx1 = node_xy(1, :) >= 1 & node_xy(1, :) < col + 1;
        idx2 = node_xy(2, :) >= 1 & node_xy(2, :) < row + 1;
        idx = idx1 & idx2;
        for j = 1:size(idx, 2)
            if idx(j) == 0
                continue;
            elseif maskImg(floor(node_xy(2, j)), floor(node_xy(1, j))) == 0
                idx(j) = 0;
            end
        end
        model.node_xyz = model.node_xyz(:, idx);
        model.node_rgb = model.node_rgb(:, idx);
    end
    writePly(model, [scenePath, '/onlyfoot.ply']);
end

%%
function [K, R, t] = readPose(scenePath) 
    K = zeros(3, 3, 12);
    R = zeros(3, 3, 12);
    t = zeros(3, 1, 12);
    filelist = dir([scenePath '/calrt/*.calrt']);
    for i = 1:length(filelist)
        data = load([scenePath '/calrt/' filelist(i).name]);
        K(:,:,i) = reshape(data(6:14), 3,3)';
        t(:,:,i) = data(15:17);
        R(:,:,i) = reshape(data(18:end), 3, 3)';
    end
end