%% dependent library: matlabmesh, gptoolbox-master
%% abstract part of mesh vertexes and its conressponding edges
%%
function point2mesh(modelName, pointsetName)
    addpath(genpath('E:/matlabCode/Library/matlabmesh'));
    addpath('E:/matlabCode/myLib');
    addpath(genpath('E:/matlabCode/Library/gptoolbox-master'));
    
    if nargin < 2
        modelName = 'E:/testModel/foot_models/meshes/gyl_right.obj';
        %pointsetName = 'E:/matlabCode/myLib/pointset.ply';
        pointsetName = 'E:/matlabCode/myLib/pointset.obj';
    end
    %pointset = Model(pointsetName);
    %pointset.readModel();
    pointset = readMesh(pointsetName);
    model = readMesh(modelName);

    %[~, ~, new_model, new_pointset] = initAlign(model.v, pointset.node_xyz);
    [~, ~, new_model, new_pointset] = initAlign(model.v, pointset.v);
    pointset.v = new_pointset;
    %pointset.node_xyz = new_pointset;
    model.v = new_model';
    
        
    
        %pointset.node_xyz = pointset.node_xyz';
        %pointset.writePly('npointset.ply');
        writeMesh(pointset, 'npointset.obj');
        writeMesh(model, 'model.obj');
        
        
        if 1
   figure;
   grid on;
   %trisurf(model.f', model.v(1, :), model.v(2, :), model.v(3, :));
   scatter3(model.v(:,1), model.v(:,2), model.v(:,3), '.', 'cdata', [1,0,0]);
   hold on;
   xlabel('x-->');
   ylabel('y-->');
   zlabel('z-->');
   %scatter3(pointMesh.v(1, :), pointMesh.v(2, :), pointMesh.v(3, :), '.');
   scatter3(pointset.node_xyz(1, :), pointset.node_xyz(2, :), pointset.node_xyz(3, :), '.', 'cdata', [0,1,0]);
   hold off;
        end
    %[index, new_pointset] = mydownSample(pointset.node_xyz, model.v); %size 1 = 3
    
    %node_hole = model.v; %size 2 = 3
    %node_hole(index, :) = new_pointset';
    
    %newmesh = abstractMesh(model, index);
    [index, node_hole] = findNeighbors(new_pointset, model.v);
    pointMesh = makeMesh(node_hole', model.f);
    pointMesh.n = estimateNormal(pointMesh);
    writeMesh(pointMesh, 'tmp.obj');


end
%%
function [newmesh] = abstractMesh(mesh, vIndex)
    if (size(vIndex, 1) ~= 1)
        vIndex = vIndex';
    end
    fIndex = [];
    for i = 1:size(vIndex, 2)
        [row, ~, ~] = find(mesh.f == vIndex(i));
        fIndex = [fIndex; row];
        fIndex = unique(fIndex);
    end
    [newmesh, ~, ~] = subMesh(mesh, fIndex);
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
    %new_model = new_model / scale;
    
    %R = [1,0,0;0,0,1;0,-1,0]*[-1,0,0;0,1,0;0,0,-1];  
    %new_model = new_model*R;
    %new_points = new_points*R;
   
    new_model = new_model + repmat(model_centre, size(new_model, 1), 1);
    new_model = new_model';
    
    new_points = new_points * scale;
    new_points = new_points + repmat(model_centre, size(points, 1), 1);
    
end
%%
function [index, node_hole] = findNeighbors(node_xyz, referenceNode) 
    if (size(node_xyz, 2) == 3)
        node_xyz = node_xyz';
    end
    if (size(referenceNode, 2) == 3)
        referenceNode = referenceNode';
    end
    numOfPt = size(node_xyz, 2); %3xnumOfPt
    numOfRef = size(referenceNode, 2); %3xnumOfRef
    
%     referenceD = sum(referenceNode.^2, 1); %1xnumOfRef
%     nodeD = sum(node_xyz.^2, 1); %1xnumOfPt
%     D = (repmat(nodeD, numOfRef, 1) + repmat(referenceD', 1, numOfPt) - 2*referenceD'*nodeD);
    
    D = zeros(numOfPt, numOfRef);
    for i = 1:numOfPt
        D(i, :) = sqrt(sum((repmat(node_xyz(:,i), 1, numOfRef) - referenceNode).^2, 1));
    end
    
    index = zeros(1, numOfPt);
    num = min(numOfPt, numOfRef);
    findedNum = 0;
    maxn = max(max(D)) + 1;

    while (findedNum < num)
        [minRow, x] = min(D);
        x(minRow == maxn) = 0;
        [x, idx] = unique(x);
        
        if x(1) == 0
            x(1) = [];
            idx(1) = [];
        end
        
        index(x) = idx;
        findedNum = findedNum + size(x, 2);
        %fprintf('%d/%d\n',findedNum,num);
     
        D(x, :) = ones(size(x, 2), numOfRef)*maxn;
        D(:, idx) = ones(numOfPt, size(x, 2))*maxn;
    end
    
    if (numOfPt > numOfRef)
        node_hole = node_xyz(:, index~=0);
        index = (index~= 0);
        return;
    end  
    
    node_hole = referenceNode;
    node_hole(:, index) = node_xyz;
end
