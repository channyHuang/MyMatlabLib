%%
%% reverse mask image
function reverseMask()
    for i = [50, 300, 450]
        filename = ['E:/RealFootData/data_new/video3/maskMan/' num2str(i, '%08d') '.jpg'];
        img = imread(filename);
        if size(img, 3) ~= 1
            img = rgb2gray(img);
        end
        
        img = 255 - img;
        %imshow(img);
        imwrite(img, filename);
    end
end