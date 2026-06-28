function [outmat] = matmove(inputmat,DirX,DirY)
%inputmat ÊäÈëÍ¼Ïñ
%outmat Êä³öÍ¼Ïñ
%direction -x=-1 +x=+1 -y=-2 +y=+2
% step 
if DirX>0;
outmat=[inputmat(:,end-DirX+1:end),inputmat(:,1:end-DirX)];
elseif DirX<0;
DirX=- DirX;
outmat=[inputmat(:,DirX+1:end),inputmat(:,1:DirX)];
elseif DirX==0;
outmat=inputmat;
end
inputmat=outmat;

if DirY>0;
outmat=[inputmat(DirY+1:end,:);inputmat(1:DirY,:)];    
elseif DirY<0;
 DirY=- DirY;
outmat=[inputmat(end-DirY+1:end,:);inputmat(1:end-DirY,:)];
elseif DirY==0;
outmat=inputmat;
end