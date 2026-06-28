clc;
clear;

%% Parameters (keep same meaning as ScanCode1)
Base = zeros(1080,1920);      % canvas
ture_scanstep = 1;            % scan step
M = 2;                        % single bright spot size
Lgth = 14;                    % base block width
Height = round(Lgth*sqrt(3)/2);
num = Lgth*Height;            % candidate scan count
pointnum = 72;                % spots per row
constraint_mode = 'center_unique'; % 'strict_pixel_unique' | 'center_unique' | 'max_repeat'
max_repeat_allowed = 1;       % only used when constraint_mode = 'max_repeat'

%% Build hexagonal multi-spot pattern (same as original logic)
Onecrop = zeros(Height,Lgth);
Onecrop(1:M,1:M) = 1;
Centercrop = zeros(Height,Lgth);
center_pos = ceil(M/2);
Centercrop(center_pos,center_pos) = 1;   % one center marker per spot
Arow = repmat(Onecrop,1,pointnum+1);
Brow = repmat(Onecrop,1,pointnum);
Arow_center = repmat(Centercrop,1,pointnum+1);
Brow_center = repmat(Centercrop,1,pointnum);
B1row = [zeros(Height,0.5*Lgth),Brow,zeros(Height,0.5*Lgth)];
B1row_center = [zeros(Height,0.5*Lgth),Brow_center,zeros(Height,0.5*Lgth)];
Crow = [Arow;B1row];
Crow_center = [Arow_center;B1row_center];
pointline = round(pointnum*2/sqrt(3));
if mod(pointline,2)==0
    Mfocal = repmat(Crow,0.5*pointline,1);
    Mfocal_center = repmat(Crow_center,0.5*pointline,1);
else
    Mfocal0 = repmat(Crow,0.5*(pointline-1),1);
    Mfocal0_center = repmat(Crow_center,0.5*(pointline-1),1);
    Mfocal = [Mfocal0;Arow];
    Mfocal_center = [Mfocal0_center;Arow_center];
end

[m,n] = size(Mfocal);
UB = floor(0.5*m);
DB = m-floor(0.5*m)-1;
LB = floor(0.5*n);
RB = n-floor(0.5*n)-1;
Base(size(Base,1)/2-UB-floor(0.5*Height):size(Base,1)/2+DB-floor(0.5*Height), ...
    size(Base,2)/2-LB-floor(0.5*Lgth):size(Base,2)/2+RB-floor(0.5*Lgth)) = Mfocal;
CenterBase = zeros(size(Base));
CenterBase(size(Base,1)/2-UB-floor(0.5*Height):size(Base,1)/2+DB-floor(0.5*Height), ...
    size(Base,2)/2-LB-floor(0.5*Lgth):size(Base,2)/2+RB-floor(0.5*Lgth)) = Mfocal_center;

%% Build candidate scan path (same as original logic)
scanstep = zeros(num,2);
A0 = zeros(Height,Lgth);
for i = 1:Lgth
    A0(:,i) = (i-1)*ture_scanstep.*ones(Height,1);
end
Dy = reshape(A0,num,1);
B0 = [(0:Height-1).*-ture_scanstep,(Height-1:-1:0).*-ture_scanstep]';
Dx = repmat(B0,0.5*Lgth,1);
scanstep = [Dy,Dx];

%% Output folder
workdir = fileparts(mfilename('fullpath'));
if isempty(workdir)
    workdir = pwd;
end
outdir = fullfile(workdir, 'output_unique_once', ...
    ['M',num2str(M),'-',num2str(num),'-L',num2str(Lgth), ...
     '-N',num2str(pointnum),'-step',num2str(ture_scanstep)]);
if ~exist(outdir, 'dir')
    mkdir(outdir);
end

%% Frame selection with configurable overlap constraint
K = 1;
C = false(size(Base));           % union coverage map
Ccount = zeros(size(Base));      % per-pixel hit count
Ccenter = false(size(Base));     % center-hit union map
accepted = 0;
rejected = 0;

for j = 1:num
    xx = scanstep(j,1);
    yy = scanstep(j,2);
    Out = logical(matmove(Base,xx,yy));
    OutCenter = logical(matmove(CenterBase,xx,yy));

    reject_frame = false;
    switch constraint_mode
        case 'strict_pixel_unique'
            reject_frame = any(Out(:) & C(:));
        case 'center_unique'
            reject_frame = any(OutCenter(:) & Ccenter(:)); % only center cannot repeat
        case 'max_repeat'
            reject_frame = any(Ccount(Out) + 1 > max_repeat_allowed);
        otherwise
            error('Unknown constraint_mode. Use strict_pixel_unique, center_unique or max_repeat.');
    end

    if reject_frame
        rejected = rejected + 1;
        continue;
    end

    filename = fullfile(outdir,[num2str(K),'.bmp']);
    imwrite(Out,filename,'bmp');
    C = C | Out;
    Ccount(Out) = Ccount(Out) + 1;
    Ccenter = Ccenter | OutCenter;
    K = K + 1;
    accepted = accepted + 1;
end

% %% Save wide-field stack images
% imwrite(uint8(C)*255, fullfile(outdir,'WF_unique.png'), 'png');
% if max(Ccount(:)) > 0
%     imwrite(uint8(255*double(Ccount)/double(max(Ccount(:)))), fullfile(outdir,'WF_count.png'), 'png');
% end
% 
% fprintf('ScanCode_unique done.\n');
% fprintf('Candidate frames: %d\n', num);
% fprintf('Accepted frames: %d\n', accepted);
% fprintf('Rejected frames: %d\n', rejected);
% fprintf('Covered pixels: %d\n', nnz(C));
% fprintf('Max gray in stacked wide-field (logical): %d\n', max(C(:)));
% fprintf('Constraint mode: %s\n', constraint_mode);
% fprintf('Max repeat count in stack: %d\n', max(Ccount(:)));