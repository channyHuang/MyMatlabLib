path = 'E:\1611_foot_data\1_mobile\m001_mobile\result_01\mask\';

for idx = 1:50:1700
filename = [num2str(idx-1, '%08d') '.jpg'];
img=imread([path filename]);

rows = size(img, 1);
cols = size(img, 2);
for i = 1:4
    for j = 1:cols
        img(i, j, :) = [0,0,0];
        img(rows-i+1, j, :) = [0,0,0];
    end
    for j = 1:rows
        img(j, i, :) = [0,0,0];
        img(j, cols-i+1, :) = [0,0,0];
    end
end

imwrite(img, [path filename]);
end


if 0
path = '';
posefiles = dir(path);
filenum = length(posefiles);


for x = 1:filenum
	posefile = [path '/' posefiles(x).name];
    load(posefile);

    filename = [num2str(x, '%04d') '.calrt'];
    fin = fopen(filename, 'wt');
    fprintf(fin, '%d\n', x);
    %distort
    for i = 1:4
        fprintf(fin, '%f\n', kc(i));
    end
    %K
    K = [fc(1), alpha_c*fc(1), cc(1); 0, fc(2), cc(2); 0, 0, 1];
    for i = 1:3
        for j = 1:3
            fprintf(fin, '%f\n', K(i, j));
        end
    end
    %t
    for i = 1:3
        fprintf(fin, '%f\n', Tc(i));
    end
    %R
    Rc = rodrigues(omc);
    for i = 1:3
        for j = 1:3
            fprintf(fin, '%f\n', Rc(i, j));
        end
    end
    fclose(fin);
end
end
