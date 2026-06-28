function [GSmask]=GsMask0(xIn,yIn,sigma,Msize)
    %xIn 列 yIn 行
    %sigma 标准差
    % Msize =[ Height,Width]
    par=[xIn,yIn,sigma];
    y0=1:Msize(1);
    x0=1:Msize(2);
    [xx0,yy0]=meshgrid(x0,y0);
    A0 = exp( -((xx0-par(1)).^2+(yy0-par(2)).^2) / (2*par(3).^2));
    GSmask=A0;
