clc;
clear;
tic;
% load Background %探测器噪声
fa=2;   % 开运算系数
boxR=6;    % 亚区域半径像素数
[dataFile0, dataPath0] = uigetfile({'*.tif';'*.*'},'Open image stack for data processing'); % 打开图像阵列,返回文件名和路径
dataFile0 = [dataPath0 dataFile0];  % 生成图像矩阵
fileNames = {dataFile0};
numFiles0 = length(fileNames);
dataFileInfo = imfinfo(dataFile0);  % 读取图像点阵数据的信息
numFrames0 = length(dataFileInfo);  % 图像点阵的数量
imgHeight0 = dataFileInfo.Height;       % 点阵数据的长度
imgWidth0 = dataFileInfo.Width;         % 点阵数据的宽度
dataAvg1= zeros(imgHeight0,imgWidth0); 
datastacks1=zeros(2*boxR+1,2*boxR+1);   % 初始化亚区域堆栈，一个点阵每个激发点分割出来的区域
datastacks2=zeros(imgHeight0,imgWidth0,numFrames0); % 初始化图像点阵数据堆栈
sumdata=zeros(imgHeight0);              % 初始化宽场图像
Border=BorderDel(imgHeight0,boxR+1);    % 初始化图像缩小的范围
%% 滤波+加入数字针孔
M=imgHeight0;
N=M;
d0=10;  % 设置滤波器的截止频率
Fliter=LPass(M,N,d0);   % 生成巴特沃斯高通滤波器
count=0;
%tic;
for jj=1:numFrames0
    dataAvg1 =double(imread(dataFile0,jj,'Info',dataFileInfo));     % 读取图像数据
    g=fftshift(fft2(dataAvg1.*Border));     % 将图像缩小到点阵图的区域附近
    J0=ifft2(ifftshift(g.*Fliter));         % 图像傅里叶变换后乘以巴特沃斯高通滤波器
    J1=mat2gray(uint16(real(J0)));          % 求图像的实数
    J1(find(J1<=0.05))=0;
    se=strel('disk', fa);                   % 创建形态学形状
    J2=imopen(J1,se);                       % 对图像进行形态学开运算，即先膨胀后腐蚀
    p=FastPeakFind(J2);                     % 寻找图像点阵点的位置，输出的是一维矩阵
    col=p(1:2:end);                         % 点阵的x坐标
    row=p(2:2:end);                         % 点阵的y坐标
    parfor pointnum=1:length(p)*0.5         % 遍历点阵每个点
        %pointnum
        LB=col(pointnum)-boxR;              % 计算该点的左边界
        RB=col(pointnum)+boxR;              % 计算该点的右边界
        UB=row(pointnum)-boxR;              % 计算该点的上边界
        DB=row(pointnum)+boxR;              % 计算该点的下边界
        subarea=dataAvg1(UB:DB,LB:RB);      % 提取该点阵的每个点  
        if sum(sum(subarea))==0             % 如果子区域全为零，直接保存该区域
            datastacks1(:,:,pointnum)=subarea;
        else
            [y0,x0]=LocaGS(subarea,[1 5]);  % 平滑
            % 滤波，并且寻找点的中心坐标，[1,5]表示高斯拟合的标准差上下限
            [m,n]=size(subarea);
            mask=GsMask0(x0,y0,1.2,[n m]);  % 生成中心位置相同的二维高斯数字针孔
             masksubarea=dataAvg1(UB:DB,LB:RB).*mask;    % 亚图像区域点乘二维高斯数字针孔
 %           masksubarea=dataAvg1(UB:DB,LB:RB);    % 亚图像区域点不加数字针孔
            datastacks1(:,:,pointnum)=masksubarea;      % 保存子区域
        end
    end
    count = count+1%进行下一层点阵
    output=RestrGS(datastacks1,p,boxR,imgHeight0);%亚区域堆栈，数据序号，处理顺序，亚区域半径，将一张点阵每一个点按照位置重构一张图片
    Border1=BorderDel(imgHeight0,boxR+10);
    output=mat2gray(output.*Border1);
    datastacks2(:,:,jj)=output;             % 叠加不同点阵的堆栈
    sumdata=sumdata+output;                 % 数字针孔滤波后的宽场图
end
toc;
Border1=BorderDel(imgHeight0,boxR+10);
sumdata=mat2gray(sumdata.*Border1);
imwrite(uint16(65535*sumdata),'E:\2026.6.23\MT1_50MS\mc_ism_input\data_z113\test1\data_z113_c1\加数字针孔1.2_fa2.tif','tif');
%save datastacks2 %点阵小孔过滤后的多阵列图
% 修改后：强制使用MAT文件7.3版本，支持大于2GB的变量
save('datastacks2.mat','datastacks2','-v7.3');
