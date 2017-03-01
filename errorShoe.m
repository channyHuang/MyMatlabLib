
outPath = 'E:\1611_foot_data\1_mobile\Sem';
groundPath = 'E:\ArtShoe2_reconstruction\code\data';
inPath = 'E:\foot_data';
infiles = dir([inPath '\*.txt']);
outfiles = dir([outPath '\*.txt']);
groundfiles = dir([groundPath '\*.txt']);

num_total = length(infiles);
param_in = zeros(10, 2*num_total);
param_ground = zeros(10, num_total);
param_out = zeros(10, 2*num_total);
for i = 1:num_total
    param_out(:, i*2-1:i*2) = load([outPath '\' outfiles(i*2-1).name]);
    nameout = strsplit(outfiles(i*2-1).name, '_');
    for j = 1:num_total
        idx = 1;
        namein = strsplit(infiles(j).name, '_');
        if (strcmp(namein(1), nameout(2)) == 1)
            idx = j;
            break;
        end
    end
    param_in(:, i*2-1:i*2) = load([inPath '\' infiles(idx).name]);
end

error = param_in - param_out;

figure;
bar([error(1, :); error(4, :)]);
set(gca,'xticklabel',{'Length','Width'});
title('Error bar of 10 data set, Left and right(unit: mm)');



if 0
for j = 1:4
    figure;
for i = 1:5
    subplot(5, 1, i)
    title(['data set ' i]);
    bar([error(:,1,i+5*(j-1))'; error(:,2,i+5*(j-1))']);
    set(gca,'xticklabel',{'left','right'});
end
suptitle(['Error of feet params (' num2str(i+5*(j-2)) '-' num2str(i+5*(j-1)) ', unit: mm)']);
end



outPath = 'E:\1611_foot_data\1_mobile';
inPath = 'E:\ArtShoe2_reconstruction\code\data';

infiles = dir([inPath '\*.txt']);
outfilesS = dir([outPath '\Same\*.txt']);
outfilesD = dir([outPath '\Diff\*.txt']);

for i = 1:length(infiles)
    param_in(:,:,i) = load([inPath '\' infiles(i).name]);
    param_outS(:,:,i) = load([outPath '\Same\' outfilesS(i).name]);
    param_outD(:,:,i) = load([outPath '\Diff\' outfilesD(i).name]);
end

errorS = param_in - param_outS;
errorD = param_in - param_outD;


figure;
for i = 1:length(infiles)
    subplot(5, 2, i)
    title(['data set ' i]);
    bar([errorS(:,1,i)'; errorS(:,2,i)']);
    set(gca,'xticklabel',{'left','right'});
end
suptitle('Error of feet params (target, unit: mm)');

figure;
for i = 1:length(infiles)
    subplot(5, 2, i)
    title(['data set ' i]);
    bar([errorD(:,1,i)'; errorD(:,2,i)']);
    set(gca,'xticklabel',{'left','right'});
end
suptitle('Error of feet params (not target, unit: mm)')

end %endif