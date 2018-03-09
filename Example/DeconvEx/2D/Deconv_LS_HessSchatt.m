%-----------------------------------------------------------
% Deconv_LS_HessSchatt script: Deconvolution by minimizing the
% Least-Squares function  plus the Hessian-Schatten regularizer:
%     0.5 ||Hx - y||^2  + lamb*||Hess*x||_{1,S_p}
% using 
%      - Chambolle-Pock
%      - ADMM 
%
% See LinOp, LinOpConv, LinOpHess, Cost, CostL2,   
% CostMixNorm1Schatt, Opti, OptiChambPock, OptiADMM, OutpuOpti
%------------------------------------------------------------
clear all; close all; clc;
help Deconv_LS_HessSchatt
%--------------------------------------------------------------
%  Copyright (C) 2017 E. Soubies emmanuel.soubies@epfl.ch
%
%  This program is free software: you can redistribute it and/or modify
%  it under the terms of the GNU General Public License as published by
%  the Free Software Foundation, either version 3 of the License, or
%  (at your option) any later version.
%
%  This program is distributed in the hope that it will be useful,
%  but WITHOUT ANY WARRANTY; without even the implied warranty of
%  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%  GNU General Public License for more details.
%
%  You should have received a copy of the GNU General Public License
%  along with this program.  If not, see <http://www.gnu.org/licenses/>.
%---------------------------------------------------------------

% -- fix the random seed (for reproductibility)
rng(1);

% -- Input image and psf
load('StarLikeSample');    % Load image (variable im)
load('psf');               % Load psf (variable psf)
imdisp(im,'Input Image',1);

% -- Image padding
impad=zeros(512); idx=129:384;
impad(idx,idx)=im;

% -- Convolution Operator definition
H=LinOpConv(fft2(psf));

% -- Generate data
load('data');    % load data (variable y)
imdisp(y(idx,idx),'Convolved and noisy data',1);
sz=size(y);

% -- Functions definition
LS=CostL2([],y);                 % Least-Sqaures data term
F=LS*H;
F.doPrecomputation=1;
Hess=LinOpHess(sz);                  % Hessian Operator
R_1sch=CostMixNormSchatt1([sz,3],1); % Mixed Norm 1-Schatten (p=1)
lamb=2e-3;                           % Hyperparameter

% -- Chambolle-Pock  LS + ShattenHess
CP=OptiChambPock(lamb*R_1sch,Hess,F);
CP.OutOp=OutputOpti(1,impad,40);
CP.tau=1;        % algorithm parameters
CP.sig=0.02;     %
CP.ItUpOut=10;   % call OutputOpti update every ItUpOut iterations
CP.maxiter=200;  % max number of iterations
CP.run(y);       % run the algorithm 

% -- ADMM LS + ShattenHess
Fn={lamb*R_1sch};
Hn={Hess};
rho_n=[1e-1];
ADMM=OptiADMM(F,Fn,Hn,rho_n);
ADMM.OutOp=OutputOpti(1,impad,40);
ADMM.ItUpOut=10;   % call OutputOpti update every ItUpOut iterations
ADMM.maxiter=200;  % max number of iterations
ADMM.run(y);       % run the algorithm 

% -- Display
imdisp(CP.OutOp.evolxopt{end}(idx,idx),'LS + Hess (CP)',1);
imdisp(ADMM.OutOp.evolxopt{end}(idx,idx),'LS + Hess (ADMM)',1);
figure; plot(CP.OutOp.iternum,CP.OutOp.evolcost,'LineWidth',1.5);grid; set(gca,'FontSize',12);xlabel('Iterations');ylabel('Cost');
hold all;plot(ADMM.OutOp.iternum,ADMM.OutOp.evolcost,'LineWidth',1.5); set(gca,'FontSize',12);xlabel('Iterations');ylabel('Cost');
legend('CP','ADMM');title('Cost evolution');

figure;subplot(1,2,1); grid; hold all; title('Evolution SNR');set(gca,'FontSize',12);
semilogy(CP.OutOp.iternum,CP.OutOp.evolsnr,'LineWidth',1.5); 
semilogy(ADMM.OutOp.iternum,ADMM.OutOp.evolsnr,'LineWidth',1.5);
legend('LS+TV (CP)','LS+TV (ADMM)');xlabel('Iterations');ylabel('SNR (dB)');
subplot(1,2,2);hold on; grid; title('Runing Time (200 iterations)');set(gca,'FontSize',12);
orderCol=get(gca,'ColorOrder');
bar(1,[CP.time],'FaceColor',orderCol(1,:),'EdgeColor','k');
bar(2,[ADMM.time],'FaceColor',orderCol(2,:),'EdgeColor','k');
set(gca,'xtick',[1 2]);ylabel('Time (s)');
set(gca,'xticklabels',{'LS+HESS (CP)','LS+HESS (ADMM)'});set(gca,'XTickLabelRotation',45)


