%%
function drawPoseOnly()
    refPath = 'E:/ArtShoe2_reconstruction/code/data';
    resPath = 'E:/1611_foot_data/1_mobile';
    reflists = [dir([refPath '/f*.txt']); dir([refPath '/m*.txt'])];
    reslists = [dir([refPath '/f*.txt']); dir([refPath '/m*.txt'])];
    num_file = length(reflists);
    refParams = zeros(10, 2, num_file);
    resParams = zeros(10, 2, num_file);
    for i = 1:num_file
        refParams(:,:,i) = load([refPath '/' reflists(i).name]);
        resParams(:,:,i) = load([resPath '/' reslists(i).name]);
    end
    
    figure;
    for i = 1:num_file
    subplot(10, 1, i);
    bar([refParams(:,1,i) - resParams(:,1, i) refParams(:,2,i) - resParams(:,2, i)]);
    if i == 1
        title('Error of foot params estimated');
    end
    end
    legend('left','right');  
    xlabel('dataset');  
    ylabel('error: mm');  
    
end

%% pose
function drawPoseOnly_() 
k = 1;
for i = 1:1
    figure;
    for j = 1:2
        scenePathName = ['E:/1611_foot_data/1_mobile/f00' num2str(i) '_mobile/result_0' num2str(j-1)];
        poseDir = [scenePathName '/visualSFM.nvm.cmvs/00'];
        [K, R, t, sfmIndex] = readPose(poseDir);    
        grid on;
        subplot(2, 1, k);
        draw(R, t);
        xlabel('x-->');
        ylabel('y-->');
        zlabel('z-->');
        hold off;
        
        k = k+1;
    end
end

end
%%
function drawsingle(axis, no)
hold on;
line([axis(1, 1), axis(2, 1)], [axis(1, 2), axis(2, 2)],[axis(1, 3), axis(2, 3)], 'Color', 'r');
view(3);
line([axis(1, 1), axis(3, 1)], [axis(1, 2), axis(3, 2)],[axis(1, 3), axis(3, 3)], 'Color', 'g');
line([axis(1, 1), axis(4, 1)], [axis(1, 2), axis(4, 2)],[axis(1, 3), axis(4, 3)], 'Color', 'b');

text(axis(1, 1), axis(1, 2), axis(1, 3), num2str(no));
end
%%
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
        str = strsplit(buf, '/');
        str = str{length(str)};
        orgIndex = sscanf(str, '%d.jpg');
        sfmIndex(i) = orgIndex;
        buf = fscanf(fid, '%f', 3);
        K(:, :, i) = [buf(1), 0, buf(2); 0, buf(1), buf(3); 0, 0, 1];
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
%%