function showPoseError(R1, t1, R2, t2) 
    if (size(R1, 3) ~= size(R2, 3) | size(t1, 3) ~= size(t2, 3) | size(R1, 3) ~= size(t1, 3) | size(R2, 3) ~= size(t2, 3))
        fprintf('Error in showPoseError: size not equal');
        return;
    end
    
    %remove first frame
    R1 = R1(:,:,2:end);
    t1 = t1(:,:,2:end);
    R2 = R2(:,:,2:end);
    t2 = t2(:,:,2:end);
    
    numOfFrame = size(R1, 3) - 1;
    errR = zeros(numOfFrame, 1);
    errt = zeros(numOfFrame, 1);
    for i = 1:numOfFrame
        R1(:,:,i) = R1(:,:,i+1)*transpose(R1(:,:,i));
        t1(:,:,i) = t1(:,:,i+1) - t1(:,:,i);
        R2(:,:,i) = R2(:,:,i+1)*transpose(R2(:,:,i));
        t2(:,:,i) = t2(:,:,i+1) - t2(:,:,i);
        
        E = R1(:,:,i)*transpose(R2(:,:,i));
        d(1) = E(2,3) - E(3,2);
        d(2) = E(3,1) - E(1,3);
        d(3) = E(1,2) - E(2,1);
        
        dmag = sqrt(d(3)*d(3) + d(1)*d(1) + d(2)*d(2));
        
        phi = asin (dmag/2);
        
        errR(i) = phi;
        errt(i) = t1(:,:,i)' * t2(:,:,i) / (norm(t1(:,:,i)) * norm(t2(:,:,i)));
        errt(i) = acos(errt(i));
    end
    
    figure;
    errR = real(errR);
%    errR = errR(2:end);
%    errt = errt(2:end);
%    numOfFrame = numOfFrame - 1;
    
    title('Error of IMU pose estimation');
    subplot(2, 1, 1);
    bar(1:numOfFrame, errR);
    hold on;
    line([1 numOfFrame], [mean(errR) mean(errR)], 'Color', [1,0,0]);
    title(['Error of rotation: mean=' num2str(mean(errR)) ',std=' num2str(std(errR))]);
    hold off;
    subplot(2, 1, 2);
    bar(1:numOfFrame, errt);
    hold on;
    line([1 numOfFrame], [mean(errt) mean(errt)], 'Color', [1,0,0]);
    title(['Error of translation: mean=' num2str(mean(errt)) ',std=' num2str(std(errt))]);
    hold off;
end