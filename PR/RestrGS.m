   
%函数用来将亚区域堆栈依照位置重构成一帧完整图像
%input 输入堆栈
%Loca 点的位置坐标
%boxR 堆栈中每幅图像的大小
%最终输出图像的大小
function [output]=RestrGS(input,Loca,boxR,Width);
output=zeros(Width);
p=Loca;
col=p(1:2:end);%x
row=p(2:2:end);%y
for pointnum=1:length(p)*0.5
LB=col(pointnum)-boxR;
RB=col(pointnum)+boxR;
UB=row(pointnum)-boxR;
DB=row(pointnum)+boxR; 
output(UB:DB,LB:RB)=input(:,:,pointnum);
end
