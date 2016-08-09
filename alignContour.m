%% mesh deformation

function alignContour()
    addpath(genpath('E:/matlabCode/Library/matlabmesh'));
    addpath('E:/matlabCode/myLib');
    addpath(genpath('E:/matlabCode/Library/gptoolbox-master'));

    modelName = 'E:/testModel/pmvs_onlyfoot.ply';
    mesh = Model(modelName);
    mesh.readModel();
    mesh.node_xyz = mesh.node_xyz';
    [Bmesh, ~] = bounding_box(mesh.node_xyz);
    
    refName = 'E:/testModel/foot_models/meshes/demo_right.obj';
    ref = readMesh(refName);
    [Bref, ~] = bounding_box(ref.v);
    
    [~, ~, new_model, new_pointset] = initAlign(ref.v, mesh.node_xyz);
    mesh.node_xyz = new_pointset;
    ref.v = new_model';
    
    figure;
    scatter3(ref.v(:,1), ref.v(:,2), ref.v(:,3), '.', 'cdata', [1,0,0]);
    hold on;
    scatter3(mesh.node_xyz(:,1), mesh.node_xyz(:,2), mesh.node_xyz(:,3), '.', 'cdata', [0,1,0]);
    xlabel('x-->');
    ylabel('y-->');
    zlabel('z-->');
    hold off;
    
    [index, new_pointset] = mydownSample(mesh.node_xyz, ref.v);
    
    exePath = 'DeformTransfer.exe';
    correspondName = 'corresp.txt';
    outputName = 'deform_transfer.obj';
        
    index = 1:size(min(mesh.v, pointset.v), 1);
    writeCorrespondFile(correspondName, index);
        
    params = [pointsetName ' ' modelName ' ' correspondName ' ' outputName];  
    runExe(exePath, params);
        
        
    if 0
    R = pinv(Bmesh)*Bref;
    
    scatter3(mesh.node_xyz(:,1), mesh.node_xyz(:, 2), mesh.node_xyz(:,3), '.', 'cData', [1,0,0]);
    hold on;
    scatter3(ref.v(:,1), ref.v(:,2), ref.v(:,3), '*', 'cData', [0,1,0]);
    hold on;
    mesh.node_xyz = mesh.node_xyz*R;
    scatter3(mesh.node_xyz(:,1), mesh.node_xyz(:,2), mesh.node_xyz(:,3), '+');
    hold off;
    end
    
    
    
    
    if 0 
    scenePathName = 'E:\RealFootData\data_new\video3\visualSFMResult';
    poseDir = [scenePathName '/visualSFM.nvm.cmvs/00']; 
    [K, R, t, sfmIndex, row, col] = readPose(poseDir);
    end
    
    if 0
    addpath(genpath('E:/matlabCode/Library/matlabmesh'));
    addpath('E:/matlabCode/myLib');

    modelName = 'E:/tools/pose_from_contour/data/mydata/testModel.obj';
    paramName = 'E:/result.txt';
    mesh = readMesh(modelName);
    
    Rt = load(paramName);
    R = rodrigues(Rt(1:3));
    t = Rt(4:6);
    %translate(mesh.v, R, t);
    mesh.v = R * mesh.v' + repmat(t, 1, size(mesh.v, 1)); 
    mesh.v = mesh.v';
    writeMesh(mesh, 'E:/result.obj');
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
            row = buf(2);
            col = buf(1);
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


function alignContour_old()
   model = Model('reconFlow/Mesh_2r.ply');
   scene = Model('reconFlow/scenePoints.ply');
   
   model.readModel();
   scene.readModel();
   
   [model_centre, points_centre, new_model] = initAlign(model.node_xyz, scene.node_xyz);
   model.node_xyz = new_model;   
   
   %writeObj(model, 'testModel.obj');
   
   figure;
   grid on;
   trisurf(model.triangle_node', model.node_xyz(1, :), model.node_xyz(2, :), model.node_xyz(3, :));
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
function writeObj(model, filename)
    fin = fopen(filename, 'wt');
    fprintf(fin, '');
    for i = 1:size(model.node_xyz, 2)
        fprintf(fin, 'v %f %f %f\n', model.node_xyz(1, i), model.node_xyz(2, i), model.node_xyz(3, i));
    end
    fprintf(fin, 'g foo\n');
    for i = 1:size(model.triangle_node, 2)
        fprintf(fin, 'f %d %d %d\n', model.triangle_node(1, i), model.triangle_node(2, i),model.triangle_node(3, i)); 
    end
    fprintf(fin, 'g\n');
    fclose(fin);
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