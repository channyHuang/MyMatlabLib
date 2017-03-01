%% addBottom test
function addBottom() 
    addpath(genpath('D:/useAsE/matlabCode/Library/matlabmesh'));
    addpath('D:/useAsE/matlabCode/myLib');
    addpath(genpath('D:/useAsE/matlabCode/Library/gptoolbox-master'));

    if 0
    pathName = 'D:/useAsE/testModel/';
    modelName = 'pmvs_onlyfoot.ply';
    
    model = Model([pathName modelName]);
    model.readModel();
    
    model.addBottom();
    
    writePly(model, 'tmp.ply');
    end
    
    sceneName = 'tmp.ply';
    modelName = 'D:/useAsE/';
    
    scene = Model(sceneName);
    model = Model(modelName);
    
    [~, ~, new_model, ~] = initAlign(model.node_xyz, scene.node_xyz);
    model.node_xyz = new_model;
    
    figure;
    hold on;
    xlabel('x-->');
    ylabel('y-->');
    zlabel('z-->');
    scatter3(scene.node_xyz(1, :), scene.node_xyz(2, :), scene.node_xyz(3, :), '.');
    hold off;
end

%%
function [model_centre, points_centre, new_model, new_points] = initAlign(model, points)
    if size(model, 1) == 3
        model = model';
    end
    if size(points, 1) == 3
        points = points';
    end
    model_centre = mean(model);
    new_model = model - repmat(model_centre, size(model, 1), 1);
    
    points_centre = mean(points);
    new_points = points - repmat(points_centre, size(points, 1), 1);
    
    model_max = max(max(new_model));
    points_max = max(max(new_points));

    scale = model_max / points_max;
    new_model = new_model / scale;
    
    R = [1, 0, 0; 0, 0, 1; 0, -1, 0];    
    new_model = new_model*R;
    
    new_model = new_model + repmat(points_centre, size(model, 1), 1);
    
    new_model = new_model';
end

%%
function [index, node] = mydownSample(node_xyz, model_xyz)
    %assert size(node_xyz) > size(model_xyz);
    if (size(node_xyz, 2) == 3)
        node_xyz = node_xyz';
    end
    if (size(model_xyz, 2) == 3)
        model_xyz = model_xyz';
    end
    numOfPt = size(node_xyz, 2); %3xnumOfPt
    numOfRef = size(model_xyz, 2); %3xnumOfRef
     
    D = zeros(numOfPt, numOfRef);
    for i = 1:numOfPt
        D(i, :) = sqrt(sum((repmat(node_xyz(:,i), 1, numOfRef) - model_xyz).^2, 1));
    end
    
    %while(1)
        [minRow, x] = min(D);
        [x, idx] = unique(x);
        node = node_xyz(:, x);
        index = idx;
    %end
end