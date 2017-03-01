%%
function IMUshow()
% read IMU data
if 1
filename = 'D:/rawIMUData.txt';
quaname = 'D:/rawQuaData.txt';
data = load(filename);
qua_data = load(quaname);

num_total = (size(data, 1) - 1) / 4;
%num_total = size(qua_data, 1);

R = zeros(3, 3, num_total);
t = zeros(3, 1, num_total);

for i = 1:num_total
    R(:,:,i) = data(i*4-3:i*4-1, :);
    t(:,:,i) = data(i*4,:)';
end
draw(R, t);
end

%SFMshow();
end
%%
function SFMshow()
    poseDir = 'E:/1611_foot_data/1_mobile/m006_mobile/result_00/visualSFM.nvm.cmvs/00';
    [K, R, t, sfmIndex, row, col] = readPose(poseDir);
    grid on;
    xlabel('x-->');
    ylabel('y-->');
    zlabel('z-->');
    draw(R, t);
end
%%
function draw(R, t)
unit = 1;
axis = [0, 0, 0; unit, 0, 0; 0, unit, 0; 0, 0, unit];%*norm(t(:,:,3) - t(:,:,2));
%drawsingle(axis, 0);
grid on;
xlabel('x-->');
ylabel('y-->');
zlabel('z-->');
for i = 1:size(R, 3)
    naxis = axis * R(:,:,i) + repmat(t(:, :, i)', 4, 1);
    %naxis = (axis - repmat(t(:, :, i)', 4, 1))*R(:, :, i);
    drawsingle(naxis, i);
end
end
%%
function drawsingle(axis, no)
axis0 = axis(1,:);
axis = axis - repmat(axis0, 4, 1);
axis(2, :) = axis(2, :).*0.2./norm(axis(2, :));
axis(3, :) = axis(3, :).*0.2./norm(axis(3, :));
axis(4, :) = axis(4, :).*0.2./norm(axis(4, :));
axis = axis + repmat(axis0, 4, 1);
view(3);
hold on;
line([axis(1, 1), axis(2, 1)], [axis(1, 2), axis(2, 2)],[axis(1, 3), axis(2, 3)], 'Color', 'r');
line([axis(1, 1), axis(3, 1)], [axis(1, 2), axis(3, 2)],[axis(1, 3), axis(3, 3)], 'Color', 'g');
line([axis(1, 1), axis(4, 1)], [axis(1, 2), axis(4, 2)],[axis(1, 3), axis(4, 3)], 'Color', 'b');

%pause(0.5);
%text(axis(1, 1), axis(1, 2), axis(1, 3), num2str(no));
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
            row = buf(3)*2;
            col = buf(2)*2;
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
