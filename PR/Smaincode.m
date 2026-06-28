clc;
tic;
load datastacks2;
datastacks=datastacks2;
[m,n,numframes]=size(datastacks);
boxR=6;%亚区域半径
factor=1;%矩阵放大倍率
[imgHeight0,imgWidth0]=size(datastacks(:,:,1));
x0=1:imgHeight0;
y0=1:imgWidth0;
x1=(1/factor):(1/factor):imgHeight0;
y1=(1/factor):(1/factor):imgWidth0;
[XX0,YY0]=meshgrid(x0,y0);
[XX1,YY1]=meshgrid(x1,y1);
dataAvg1= zeros(imgHeight0*factor,imgWidth0*factor);    % 初始化g1(x,y)
datastacks1=zeros(2*boxR+1,2*boxR+1,500);               % 初始化亚区域堆栈
sumdata=zeros(imgHeight0*2*factor,imgWidth0*2*factor);  % 初始化g2(x,y)
count=0;
% matlabpool local 4
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fa=2; %连通系数
se=strel('disk', fa);
for jj=1:numframes
    dataAvg0 =datastacks(:,:,jj);
    dataAvg1=interp2(XX0,YY0,dataAvg0,XX1,YY1,'cubic');     % 线性插值得到g1(x,y)
    dataAvg2=mat2gray(dataAvg1);%将插值后的图像转灰度值
    dataAvg2=imerode(dataAvg2,se);%腐蚀图像
    Loca=FastPeakFind(dataAvg2);%寻找g1图像中的峰值点
    col=Loca(1:2:end);%x，寻找峰值点的x坐标
    row=Loca(2:2:end);%y，寻找峰值点的y坐标
    parfor pointnum=1:length(Loca)*0.5
        LB=col(pointnum)-boxR;
        RB=col(pointnum)+boxR;
        UB=row(pointnum)-boxR;
        DB=row(pointnum)+boxR;
        datastacks1(:,:,pointnum)=dataAvg1(UB:DB,LB:RB);%寻找峰值点的亚图像区域
    end
    count=count+1
    output=Restr(datastacks1,Loca,boxR,imgHeight0,factor);%亚区域堆栈，数据序号，处理顺序，参考点位置，亚区域尺寸，将g1每个荧光点复制到g2矩阵中
    sumdata=sumdata+output;%将所有点阵图叠成一张图，至此像素重定位结束
end
toc;
%delete(gcp('nocreate'));%关闭并行配置
imwrite(mat2gray(sumdata),'E:\2026.6.23\MT1_50MS\mc_ism_input\data_z113\test1\data_z113_c1\像素重定位1.2_boxr6_factor1.tif')