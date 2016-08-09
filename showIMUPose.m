%%
function showIMUPose
    showProjectionSfm();
%show origin imu pose 
if 1
%    data = load('E:/mycode/gtsamTest/build/mainFunction/rawIMUData.txt');
data = load('E:/mycode/gtsamTest/build/imuFactorgraph.txt');
for i = 1:size(data, 1)/4
    R(:,:, i) = data(4*i - 3:4*i-1,:);
    t(:,:,i) = data(4*i,:)';
end
draw(R, t);
end
R1 = R;
t1 = t;

%show sfm pose
if 1
    poseDir = 'E:/RealFootData/data_new/video3/visualSFMResult/visualSFM.nvm.cmvs/00';
    [K, R, t, sfmIndex] = readPose(poseDir);
    grid on;
    xlabel('x-->');
    ylabel('y-->');
    zlabel('z-->');
    draw(R, t);
end

close all;
showPoseError(R1, t1, R, t);
end

function draw(R, t)
axis = [0, 0, 0; 1, 0, 0; 0, 1, 0; 0, 0, 1]*norm(t(:,:,3) - t(:,:,2));
%    drawsingle(axis, 0);
grid on;
xlabel('x-->');
ylabel('y-->');
zlabel('z-->');
for i = 2:size(R, 3)
    naxis = (axis - [t(:, :, i)';t(:, :, i)';t(:, :, i)';t(:, :, i)'])*R(:, :, i);
    drawsingle(naxis, i);
end
end

function drawsingle(axis, no)
hold on;
line([axis(1, 1), axis(2, 1)], [axis(1, 2), axis(2, 2)],[axis(1, 3), axis(2, 3)], 'Color', 'r');
view(3);
line([axis(1, 1), axis(3, 1)], [axis(1, 2), axis(3, 2)],[axis(1, 3), axis(3, 3)], 'Color', 'g');
line([axis(1, 1), axis(4, 1)], [axis(1, 2), axis(4, 2)],[axis(1, 3), axis(4, 3)], 'Color', 'b');

text(axis(1, 1), axis(1, 2), axis(1, 3), num2str(no));
end

%%
function showProjectionSfm(ply_filename, pose_filename)
close all;
clear;

if (nargin < 2)
    ply_filename = 'E:/RealFootData/data_new/video3/randscene/synth_0.ply';
    pose_filename = 'E:/RealFootData/data_new/video3/randscene/synth_0.out';
end

[K, R, t] = readBundlePose(pose_filename);
[node_xyz, node_rgb] = ply_to_points(ply_filename);

DrawAll = 1;
C = zeros(3, 1, size(R, 3));
for i = 1:size(R, 3)
    C(:, :, i) = -t(:,:,i)' * R(:, :, i);
end
C = C(:, :, 10:end);
if DrawAll
    scatter3(C(1,:),C(2,:), C(3,:), '*');
    grid on;
    hold on;
%    scatter3(node_xyz(1,:), node_xyz(2,:), node_xyz(3,:), '.', 'cdata', node_rgb'./255.0);
    hold off;
end

Draw = 0;
if Draw
    for framenum = 10:size(R, 3)
         node_xy = K(:,:,framenum)*[R(:,:,framenum), t(:,:,framenum)]* [node_xyz; ones(1, size(node_xyz, 2))];
        node_xy(1, :) = node_xy(1, :) ./ node_xy(3, :);
        node_xy(2, :) = node_xy(2, :) ./ node_xy(3, :);
        
        subplot(121);
            scatter(node_xy(1, :), -node_xy(2, :), '.', 'cdata', node_rgb'./255);
            subplot(122);
            scatter(floor(node_xy(1, :)), floor(node_xy(2, :)), '*', 'cdata', node_rgb'./255 );
    end
end

onlyFoot = 1;

if onlyFoot
maskdir = 'E:/RealFootData/data_new/video3/randscene/mask';
maskfile = dir([maskdir '/*.jpg']);


maskIndex = [1, 2, 3, 4, 5, 6];
idx = [];
for i = 1:size(maskfile)
    maskimg = imread([maskdir '/' maskfile(i).name]);
    maskimg = im2bw(maskimg);
    framenum = i;
        node_xy = K(:,:,framenum)*[R(:,:,framenum), t(:,:,framenum)]* [node_xyz; ones(1, size(node_xyz, 2))];
        node_xy(1, :) = node_xy(1, :) ./ node_xy(3, :);
        node_xy(2, :) = node_xy(2, :) ./ node_xy(3, :);
        
        node_xy = floor(node_xy(1:2, :));
        node_xy = node_xy(:, (node_xy(1,:) > 0) & (node_xy(2,:) > 0));
        
        scatter(node_xy(1, :), node_xy(2, :), '.');
        close all;
        
        idx = [idx; maskimg(node_xy) == 0];
end
end

end

function [K, R, t] = readBundlePose(pose_filename) 
    fid = fopen(pose_filename);
    buf = fgetl(fid);
    buf = fgetl(fid);
    filenum = sscanf(buf, '%d', 1);

    R = zeros(3, 3, filenum);
    t = zeros(3, 1, filenum);
    K = ones(3, 3, filenum);
    
    for i = 1:filenum
        buf = fscanf(fid, '%f', 15);
        %K(:, :, i) = [buf(1), 0, buf(2); 0, buf(1), buf(3); 0, 0, 1];
        K(:, :, i) = [1500, 0, 960; 0, 1500, 540; 0, 0, 1];
        RT = reshape(buf, 3, 5)';
        R(:, :, i) = RT(2:4, :);
        t(:,:,i) = RT(5, :);
    end
    fclose(fid);
end

%%
%%
function [K, R, t, sfmIndex] = readPose(poseDir)
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
%        sfmIndex(orgIndex + 1) = i;

        buf = fscanf(fid, '%f', 3);
%        K(:, :, i) = [buf(1), 0, buf(2); 0, buf(1), buf(3); 0, 0, 1];
        K(:, :, orgIndex) = [buf(1), 0, buf(2); 0, buf(1), buf(3); 0, 0, 1];

        buf = fscanf(fid, '%f', 26);
    end
    
    fclose(fid);
    
    posefiles = dir([poseDir '/txt/*.txt']);
    %filenum = length(posefiles);
    
    if (filenum ~= length(posefiles))
        fprintf('Error: num of pose files not equal to filenum value');
    end
    
    for no = 1:filenum
        posefile = [poseDir '/txt/' posefiles(no).name];
        fid = fopen(posefile, 'rt');
        buf = fscanf ( fid, '%s', 1 );
        buf = fscanf(fid, '%f');
        fclose(fid);
        
        i = sfmIndex(no);
        P(:, :, i) = reshape(buf, 4, 3)';
        RT = inv(K(:, :, i))*P(:, :, i);
        R(:, :, i) = RT(1:3, 1:3);
        t(:,:,i) = RT(1:3, 4);
        
    end
end