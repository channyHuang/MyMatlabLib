function exercise() 
    addpath(genpath('E:/matlabCode/Library/matlabmesh'));
    addpath('E:/matlabCode/myLib');
    addpath(genpath('E:/matlabCode/Library/gptoolbox-master'));
     
    pointsetName = 'E:/matlabCode/tmp.ply';
    pts = Model(pointsetName);
    pts.readModel();
    
    pts.addBottom();
    writePly(pts, 'newtmp.ply');
end

function ply2txt()
    addpath(genpath('E:/matlabCode/Library/matlabmesh'));
    addpath('E:/matlabCode/myLib');
    addpath(genpath('E:/matlabCode/Library/gptoolbox-master'));
     
    pointsetName = 'E:/matlabCode/myLib/pointset.ply';
    pts = Model(pointsetName);
    pts.readModel();
    
    for i = 1:size(pts.normal, 2)
        pts.normal(:,i) = pts.normal(:,i) ./ norm(pts.normal(:,i));
    end
    
    outputName = 'E:/tmp.txt';
    fin = fopen(outputName, 'wt');
    fprintf(fin, '%f %f %f %f %f %f\n', pts.node_xyz(1, :),  pts.node_xyz(2, :),  pts.node_xyz(3, :),  pts.normal(1, :),  pts.normal(2, :),  pts.normal(3, :));
    fclose(fin);
end

function exercise_1()
   addpath(genpath('E:/matlabCode/Library/matlabmesh'));
    addpath('E:/matlabCode/myLib');
    addpath(genpath('E:/matlabCode/Library/gptoolbox-master'));
     
    pointsetName = 'E:/matlabCode/myLib/pointset.obj';
    pointset = readMesh(pointsetName);
    
    R = [1,0,0;0,0,1;0,-1,0]*[-1,0,0;0,1,0;0,0,-1];  
    pointset.v = pointset.v*R;
    writeMesh(pointset, 'npointset.obj');
end