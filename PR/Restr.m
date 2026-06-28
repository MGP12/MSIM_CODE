
%函数用来将亚区域堆栈依照位置重构成一帧完整图像
function [output]=Restr(input,Loca,boxR,Width,factor);
output=zeros(Width*factor*2);
col=Loca(1:2:end);%x
row=Loca(2:2:end);%y
for pointnum=1:length(Loca)*0.5
LB=col(pointnum)*2-boxR;
RB=col(pointnum)*2+boxR;
UB=row(pointnum)*2-boxR;
DB=row(pointnum)*2+boxR; 
output(UB:DB,LB:RB)=input(:,:,pointnum);
end
