% Copyright (c)2013, The Board of Trustees of The Leland Stanford Junior
% University. All rights reserved.
% 
% Redistribution and use in source and binary forms, with or without 
% modification, are permitted provided that the following conditions are 
% met:
% 单高斯拟合雅克比矩阵
% Redistributions of source code must retain the above copyright notice, 
% this list of conditions and the following disclaimer.
% Redistributions in binary form must reproduce the above copyright notice, 
% this list of conditions and the following disclaimer in the documentation 
% and/or other materials provided with the distribution.
% Neither the name of the Leland Stanford Junior University nor the names 
% of its contributors may be used to endorse or promote products derived 
% from this software without specific prior written permission.
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS 
% IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
% THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR 
% PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR 
% CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, 
% EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, 
% PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR 
% PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF 
% LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING 
% NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS 
% SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

function jacobian = f_singleGaussianVectorJacobian(par,ii,jj)
  jacobian1 = exp( -((ii-par(2)).^2+(jj-par(3)).^2) / (2*par(4).^2));
  jacobian3 = par(1) .* exp( -((ii-par(2)).^2+(jj-par(3)).^2) / (2*par(4).^2)) ...
          .* (ii-par(2)) / (par(4).^2);
  jacobian4 = par(1).*exp( -((ii-par(2)).^2+(jj-par(3)).^2) / (2*par(4).^2)) ...
          .* (jj-par(3)) / (par(4).^2);
  jacobian7 = par(1).*exp( -((ii-par(2)).^2+(jj-par(3)).^2) / (2*par(4).^2)) ...
          .* ((ii-par(2)).^2+(jj-par(3)).^2) / (par(4).^3);
  jacobian = [reshape(jacobian1,[],1) reshape(jacobian3,[],1)  reshape(jacobian4,[],1) reshape(jacobian7,[],1) ];
