function [Output]=BorderDel(M,Width);
Output=ones(M);
Output(1:Width,:)=0;
Output(:,1:Width)=0;
Output(M-Width+1:M,:)=0;
Output(:,M-Width+1:M)=0;