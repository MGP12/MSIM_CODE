% 二阶巴特沃斯(Butterworth)高通滤波器 
function [h]=LPass(M,N,d0);
m=fix(M/2);n=fix(N/2);
nn=2;%阶数
for  i=1:M;
     for j=1:N;
          d=sqrt((i-m)^2+(j-n)^2);            
                   if (d==0)               
                       h(i,j)=0; 
           else 
             h(i,j)=1/(1+0.414*(d0/d)^(2*nn));% 计算传递函数            
                   end 
        end 
end 