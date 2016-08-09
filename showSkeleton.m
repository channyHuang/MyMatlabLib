function showSkeleton() 
    addpath(genpath('E:/matlabCode/Library/matlabmesh'));
    addpath('E:/matlabCode/myLib');
    addpath(genpath('E:/matlabCode/Library/gptoolbox-master'));

    pathName = 'E:/testModel/';
    modelName = 'pmvs_onlyfoot.ply';
    skeletonName = 'pmvs_onlyfoot.ply.skel';
    
    skeletons = readSkeleton([pathName skeletonName]);
    
    model = Model([pathName modelName]);
    model.readModel();
    model.node_xyz = model.node_xyz';
    
    [~, ~, ~, new_pointset] = initAlign(model.node_xyz, skeletons);
    skeletons = new_pointset;
    
    figure;
    scatter3(model.node_xyz(:,1), model.node_xyz(:,2), model.node_xyz(:,3), '.', 'cdata', [1,0,0]);
    hold on;
    xlabel('x-->');
    ylabel('y-->');
    zlabel('z-->');
    scatter3(skeletons(:,1), skeletons(:,2), skeletons(:,3), '*', 'cdata', [0,1,0]);
    hold off;
    
    writeSkeleton([pathName 'pmvs_onlyfoot.ply.skel'], skeletons);
end

function writeSkeleton(filename, skeletons)
    fin = fopen(filename, 'wt');
    fprintf(fin, 'CN 1\nCNN %d\n', size(skeletons, 1));
    fprintf(fin, '%f %f %f\n', skeletons(:,1), skeletons(:, 2), skeletons(:, 3));
    fclose(fin);
end

function [skeletons] = readSkeleton(filename)
    skeletons = [];
    fin = fopen(filename, 'r');
    line = fgetl(fin);
    numOfSke = sscanf(line, '%*s %d');
    for i = 1:numOfSke
        line = fgetl(fin);
        numOfPt = sscanf(line, '%*s %d');
        %for j = 1:numOfPt
            tmpdata = fscanf(fin, '%f', numOfPt * 3);
            skeletons = [skeletons; reshape(tmpdata, 3, numOfPt)'];
            line = fgetl(fin);
        %end
    end
    fclose(fin);
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

    new_points = new_points + repmat(model_centre, size(new_points, 1), 1);
    
    scale = model_max / points_max;
    new_model = new_model / scale;
    
    R = [1, 0, 0; 0, 0, 1; 0, -1, 0];    
    new_model = new_model*R;
    
    new_model = new_model + repmat(model_centre, size(model, 1), 1);
    
    new_model = new_model';
end