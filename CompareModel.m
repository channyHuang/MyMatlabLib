% target:
%   Compare standard model and reconstruct model, output their difference
% input:
%   point cloud generate by visualSFM, delete background and rest only foot
%   standard model
% output:
%   ratio of two models
function CompareModel()
    pathName = 'D:/useAsE/mycode/AllInOne_ForGraduate/build/';
    modelr = 'testFunction/3-3.ply';
    models = 'testFunction/gyl.ply';
    [bBoxR, areaR, ankleR, modelR] = param(modelr, pathName, 'Standard');
    [bBoxS, areaS, ankleS, modelS] = param(models, pathName, 'Standard');
    
    %addBottom(modelR, bBoxR);
    %modelR.writePly('D:/useAsE/tmp.ply');
    
    bBr = bBoxR(:,2) - bBoxR(:,1);
    bBs = bBoxS(:,2) - bBoxS(:,1);
    ratioB = bBr./bBs;
    ratioC = ankleR / ankleS;
    ratioS = areaR / areaS;
    
    centerR = (bBoxR(:, 2) + bBoxR(:, 1))./2.0;
    centerS = (bBoxS(:, 2) + bBoxS(:, 1))./2.0;
    
    modelR.node_xyz = modelR.node_xyz - repmat(centerR, 1, size(modelR.node_xyz, 2));
    modelR.node_xyz = modelR.node_xyz ./ (sum(ratioB)/3.0);
    modelR.node_xyz = modelR.node_xyz + repmat(centerS, 1, size(modelR.node_xyz, 2));
    
    show(modelR);
    hold on;
    show(modelS);
    hold off;
end
% input:
%   model: standard or reconstructed model after alignment, that is to say
%   the axis of model is listed as follow:
%       x: shortest
%       y: longest
%       z: height
%       center: the center of bounding box
function addBottom(model, bBox)
    delta = (bBox(:, 2) - bBox(:, 1)) ./ 50;
    numOfNode = size(model.node_xyz, 2);
    idx = convhull(model.node_xyz(1,:), model.node_xyz(2,:));
    for x = bBox(1, 1):delta(1):bBox(1,2)
        for y = bBox(2, 1):delta(2):bBox(2, 2)
            in = inpolygon(x, y, model.node_xyz(1, idx), model.node_xyz(2, idx));
            if (in == 1)
                numOfNode = numOfNode + 1;
                model.node_xyz(:,numOfNode) = [x, y, bBox(3,1)]';
            end
        end
    end
end

% input: 
%   modelName
%   pathName
%   type:
%       standard model: x-y is the bottom plane
%       reconstruction model: reconstruct result from SFM
% output£º
%   boundingBox = [rangex; rangey; rangez]; x-> shortest, y-> longest
%   area
%   ankle = perimeter
function [boundingBox, area, ankle, model] = param(modelName, pathName, type) 
    model = Model([pathName modelName]);
    model.readModel();
    
    if (strcmp(type, 'Standard'))
        alpha = 5;
        rangey = [min(model.node_xyz(2, :)), max(model.node_xyz(2, :))];
        rangez = [min(model.node_xyz(3, :)), max(model.node_xyz(3, :))];
        rangex = [min(model.node_xyz(1, :)), max(model.node_xyz(1, :))];
    elseif (strcmp(type, 'reconstruction'))
        alpha = 0.05;
        rot = [0, 1, 0; 0, 0, -1; 1, 0, 0];
        model.node_xyz = (model.node_xyz'*rot)';
        
        rangez = [min(model.node_xyz(3, :)), max(model.node_xyz(3, :))];
        rangex = [min(model.node_xyz(1, :)), max(model.node_xyz(1, :))];
        rangey = [min(model.node_xyz(2, :)), max(model.node_xyz(2, :))];
        disy = rangey(2) - rangey(1);
        disx = rangex(2) - rangex(1);
        stepx = 0;
        stepy = 0;
        for step = 1:360
            theta = pi/180.0;
            rot = [cos(theta), sin(theta), 0; -sin(theta), cos(theta), 0; 0, 0, 1];
            model.node_xyz = (model.node_xyz'*rot)';
            
            rangex = [min(model.node_xyz(1, :)), max(model.node_xyz(1, :))];
            rangey = [min(model.node_xyz(2, :)), max(model.node_xyz(2, :))];
            
            if (disy < rangey(2) - rangey(1)) 
                disy = rangey(2) - rangey(1);
                stepy = step;
            end
            if (disx > rangex(2) - rangex(1)) 
                disx = rangex(2) - rangex(1);
                stepx = step;
            end
        end
        
        if (abs(stepx - stepy) < 5) 
            step = (stepx + stepy) / 2;
        else 
            step = stepx;
        end
        theta = step*pi/180.0;
        rot = [cos(theta), sin(theta), 0; -sin(theta), cos(theta), 0; 0, 0, 1];
        model.node_xyz = (model.node_xyz'*rot)';
        rangex = [min(model.node_xyz(1, :)), max(model.node_xyz(1, :))];
        rangey = [min(model.node_xyz(2, :)), max(model.node_xyz(2, :))];
    else 
        rangex = 0;
        rangey = 0;
        rangez = 0;
    end
    
    boundingBox = [rangex; rangey; rangez];
    
    targety = (rangey(2) + rangey(1)) / 5.0;% should be 2/3 ?!
    idx = (abs(model.node_xyz(2, :) - targety) < alpha);
    [convIdx, area] = convhull(model.node_xyz(1,idx), model.node_xyz(3,idx));
    %area = polyarea(model.node_xyz(1,idx), model.node_xyz(3,idx));
    ankle = PolyPerimeter(model.node_xyz(1,convIdx), model.node_xyz(3,convIdx));
    %show
    if (0)
        figure;
        scatter(model.node_xyz(1,idx), model.node_xyz(3,idx));
        show(model);
    end
    
end
% X and Y: 1 x N size
function result = PolyPerimeter(X, Y) 
    len = size(X, 2);
    result = 0;
    for i = 2:len
        result = result + sqrt((X(i) - X(i-1))*(X(i) - X(i-1)) + (Y(i) - Y(i-1))*(Y(i) - Y(i-1)));
    end
    result = result + sqrt((X(1) - X(len))*(X(1) - X(len)) + (Y(1) - Y(len))*(Y(1) - Y(len)));
end

function show(model) 
        figure;
        scatter3(model.node_xyz(1,:), model.node_xyz(2,:), model.node_xyz(3,:), '.');
        hold on;
        grid on;
        xlabel('x-->');
        ylabel('y-->');
        zlabel('z-->');
        hold off;
end