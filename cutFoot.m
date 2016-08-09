%% cut foot model into 2 parts
function cutFoot() 
    addpath(genpath('E:/matlabCode/Library/matlabmesh'));
    addpath('E:/matlabCode/myLib');
    addpath(genpath('E:/matlabCode/Library/gptoolbox-master'));
    if 1
        pathName = 'E:/testModel/foot_models/meshes/';
        modelName = 'gyl_left.ply';
    
        model = Model([pathName modelName]);
    model.readModel();
    model.node_xyz = model.node_xyz';
    
    figure;
    scatter3(model.node_xyz(:,1), model.node_xyz(:,2), model.node_xyz(:,3), '.', 'cdata', [1,0,0]);
    hold on;
    xlabel('x-->');
    ylabel('y-->');
    zlabel('z-->');
    hold off;
    
    idx1 = (model.node_xyz(:,2) >= 0);
    nodes1 = model.node_xyz(idx1, :);
    figure;
    scatter3(nodes1(:,1), nodes1(:,2), nodes1(:,3), '.', 'cdata', [1,0,0]);
    hold on;
    xlabel('x-->');
    ylabel('y-->');
    zlabel('z-->');
    hold off;
    
    %idx2 = (model.node_xyz(:,2) < 0);
    nodes2 = model.node_xyz(~idx1, :);
    figure;
    scatter3(nodes2(:,1), nodes2(:,2), nodes2(:,3), '.', 'cdata', [1,0,0]);
    hold on;
    xlabel('x-->');
    ylabel('y-->');
    zlabel('z-->');
    hold off;
    end
    
    
    
    model.node_xyz = nodes1';
    model.writePly('part1.ply');
    model.node_xyz = nodes2';
    model.writePly('part2.ply');
end