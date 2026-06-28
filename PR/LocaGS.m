function [Y0,X0]=LocaGS(InputIM,sigmaBounds);
    %InputIM 输入图像 
    %sigmaBounds 估计的标准差的上下限
    %Y0 行 X0 列
    [m,n]=size(InputIM);%亚区域堆栈图像像素点个数
    xx=1:m;
    yy=1:n;
    [xIdx,yIdx]=meshgrid(yy,xx);
    image0 = imfilter(InputIM, fspecial('gaussian', size(InputIM),1.0), 'same', 'conv');%高斯滤波
    image0=image0-min(min(image0));
    image0=image0./max(max(image0));%这两步都是归一化操作
    range=find(image0<0.30);%以最大值的1/3为阈值；
    image0(range)=0;%将小于阈值的强度设为0
    [tempY, tempX] = ind2sub([m,n], ...     %%ind2sub 把数组中元素索引值转换为该元素在数组中对应的下标。找亚区域堆栈图强度最大值它对应的坐标           
                find(imregionalmax(image0)));
            tempX = tempX + min(xIdx(:))-1;
            tempY = tempY + min(yIdx(:))-1;%这两步是将寻找到的最大值坐标恢复成亚区域图像中的坐标
            temp = sortrows([tempX tempY image0(sub2ind([m n], ...
                tempY,tempX))],-3);%将最大值的坐标按照强度降序的方式排列，峰值X坐标，峰值Y坐标，峰值强度，标准差
            
    if size(temp,1)>=1
                fitParam(3) = temp(1,1);
                fitParam(2) = temp(1,2);
                fitParam(1) = temp(1,3);
                fitParam(4) = mean(sigmaBounds);
     end 
     lowerBound = [ 0 min(xIdx(:)) min(yIdx(:)) sigmaBounds(1) ];%【H1，H2，x1,x2,y1,y2,标准差1，标准差2】
     upperBound = [max(max(image0(yIdx(:,1),xIdx(1,:)))) max(xIdx(:)) max(yIdx(:)) sigmaBounds(2)];
     options = optimset('FunValCheck','on','Diagnostics','off','Jacobian','on','Display','off'); 
            %% Fit with lsqnonlin
    [fitParam,~,residual,exitflag] = lsqnonlin(@(x) ...
     f_singleGaussianVector(x,image0(yIdx(:,1),xIdx(1,:)),0,yIdx,xIdx),...
       fitParam,lowerBound,upperBound,options);
    Y0= fitParam(2);
    X0= fitParam(3);
end
