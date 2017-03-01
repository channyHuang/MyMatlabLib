function tmp()
    path = 'E:\ArtShoe2_reconstruction\code\data\f001_dc_right\data\mask';
    imglist = dir([path '/*.bmp']);
    for idx = 1:length(imglist) 
        imgname = [path '/' imglist(idx).name];
        img = imread(imgname);
        
        layer = size(img, 3);
        for i = 1:4
            for j = 1:size(img, 2)
                for k = 1:layer
                    img(i, j, k) = 0;
                end
            end
        end
        
        for i = 1:4
            for j = 1:size(img, 1)
                for k = 1:layer
                    img(j, i, k) = 0;
                end
            end
        end
        
        for i = 1:4
            for j = 1:size(img, 2)
                for k = 1:layer
                    img(size(img,1) - i + 1, j, k) = 0;
                end
            end
        end
        
        for i = 1:4
            for j = 1:size(img, 1)
                for k = 1:layer
                    img(j, size(img,2) - i + 1, k) = 0;
                end
            end
        end
    
        imwrite(img, imgname);
    end
end