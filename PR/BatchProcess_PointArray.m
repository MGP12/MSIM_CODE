function BatchProcess_PointArray()
%BatchProcess_PointArray ����������������
% ����ִ�� MainCode1���˲�+�������ջ���� Smaincode���������ض�λ��
% ԭʼ���ݣ�inputRoot\<���>\*.tif��ÿ�� 56 ֡��
% ��������ͱ����� outputRoot �¸����ļ���

clc;

%% ========== ·����������� ==========
inputRoot  = 'E:\2026.6.23\MT1_50MS\test';
outputRoot = 'E:\2026.6.23\MT1_50MS\test���';

outDirMat      = fullfile(outputRoot, '01_�������ջ_mat');   % MainCode1 �м��� datastacks2
outDirStackSum = fullfile(outputRoot, '02_���������ͼboxR6J10.02');     % MainCode1 ���յ���ͼ
outDirReloc    = fullfile(outputRoot, '03_�������ض�λͼboxR6J10.02');   % Smaincode �����ض�λͼ
logFile        = fullfile(outputRoot, '������־.txt');

fa     = 2;    % ��ͨ��ϵ������ MainCode1 / Smaincode һ�£�
boxR   = 6;    % ������뾶
factor = 1;    % Smaincode ��ֵ�Ŵ���
d0     = 10;   % ������˹��ͨ��ֹƵ��
gsMask = 1.2;  % GsMask0 ��˹��Ĥ������MainCode1.m ʹ�� 1.2��

expectedFrames = 56;  % ÿ������֡��������ʱ������

%% ========== ��ʼ�����Ŀ¼ ==========
outDirs = {outDirMat, outDirStackSum, outDirReloc};
for k = 1:numel(outDirs)
    if ~exist(outDirs{k}, 'dir')
        mkdir(outDirs{k});
    end
end

if ~exist(inputRoot, 'dir')
    error('����Ŀ¼������: %s', inputRoot);
end

layerDirs = dir(inputRoot);
layerDirs = layerDirs([layerDirs.isdir]);
layerDirs = layerDirs(~ismember({layerDirs.name}, {'.', '..'}));
layerNames = {layerDirs.name};
layerNums  = str2double(layerNames);
if any(isnan(layerNums))
    [~, sortIdx] = sort(layerNames);
else
    [~, sortIdx] = sort(layerNums);
end
layerDirs = layerDirs(sortIdx);
numLayers = numel(layerDirs);

fprintf('������ %d �����ļ��У���ʼ��������...\n', numLayers);
logFp = fopen(logFile, 'a');
fprintf(logFp, '\n========== %s ==========\n', datestr(now));
fprintf(logFp, '����: %s\n���: %s\n����: %d\n', inputRoot, outputRoot, numLayers);

totalTic = tic;
okCount = 0;
failList = {};

for li = 1:numLayers
    layerName = layerDirs(li).name;
    layerPath = fullfile(inputRoot, layerName);
    layerTic  = tic;

    fprintf('\n[%d/%d] ������ %s ...\n', li, numLayers, layerName);

    try
        imgList = dir(fullfile(layerPath, '*.tif'));
        imgList = imgList(~[imgList.isdir]);
        if isempty(imgList)
            error('δ�ҵ� tif �ļ�');
        end
        [~, imgSortIdx] = sort({imgList.name});
        imgList = imgList(imgSortIdx);
        numFrames = numel(imgList);
        if numFrames ~= expectedFrames
            warnMsg = sprintf('�� %s: ֡�� %d������ %d', layerName, numFrames, expectedFrames);
            warning(warnMsg);
            fprintf(logFp, '����: %s\n', warnMsg);
        end

        [datastacks2, stackSum] = processMainCode1Layer(layerPath, imgList, fa, boxR, d0, gsMask);

        matPath = fullfile(outDirMat, sprintf('layer_%s_datastacks2.mat', layerName));
        save(matPath, 'datastacks2', '-v7.3');

        stackSumPath = fullfile(outDirStackSum, sprintf('layer_%s_���������_fa%d_boxR%d.tif', layerName, fa, boxR));
        imwrite(uint16(65535 * stackSum), stackSumPath, 'tif');

        relocSum = processSmaincode(datastacks2, boxR, factor, fa);
        relocPath = fullfile(outDirReloc, sprintf('layer_%s_�������ض�λ_boxR%d_factor%d.tif', layerName, boxR, factor));
        imwrite(mat2gray(relocSum), relocPath, 'tif');

        elapsed = toc(layerTic);
        okCount = okCount + 1;
        msg = sprintf('�� %s ��� (%.1f s)', layerName, elapsed);
        fprintf('  %s\n', msg);
        fprintf(logFp, 'OK  %s\n', msg);

    catch ME
        elapsed = toc(layerTic);
        failList{end+1} = layerName; %#ok<AGROW>
        errMsg = sprintf('�� %s ʧ�� (%.1f s): %s', layerName, elapsed, ME.message);
        fprintf('  ����: %s\n', ME.message);
        fprintf(logFp, 'FAIL %s\n', errMsg);
    end
end

totalElapsed = toc(totalTic);
summary = sprintf('������������: �ɹ� %d / %d���ܺ�ʱ %.1f s', okCount, numLayers, totalElapsed);
fprintf('\n%s\n', summary);
fprintf(logFp, '%s\n', summary);
if ~isempty(failList)
    fprintf('ʧ�ܲ�: %s\n', strjoin(failList, ', '));
    fprintf(logFp, 'ʧ�ܲ�: %s\n', strjoin(failList, ', '));
end
fclose(logFp);

end

%% ========== �ֲ�������MainCode1 ���㴦�� ==========
function [datastacks2, sumdata] = processMainCode1Layer(layerPath, imgList, fa, boxR, d0, gsMask)
    numFrames = numel(imgList);
    firstFile = fullfile(layerPath, imgList(1).name);
    info = imfinfo(firstFile);
    imgHeight0 = info.Height;
    imgWidth0  = info.Width;

    datastacks1 = zeros(2*boxR+1, 2*boxR+1);
    datastacks2 = zeros(imgHeight0, imgWidth0, numFrames);
    sumdata     = zeros(imgHeight0);
    Border      = BorderDel(imgHeight0, boxR+1);
    Fliter      = LPass(imgHeight0, imgHeight0, d0);
    se          = strel('disk', fa);

    for jj = 1:numFrames
        dataFile = fullfile(layerPath, imgList(jj).name);
        dataAvg1 = double(imread(dataFile));

        g  = fftshift(fft2(dataAvg1 .* Border));
        J0 = ifft2(ifftshift(g .* Fliter));
        J1 = mat2gray(uint16(real(J0)));
        J1(J1 <= 0.02) = 0;
        J2 = imopen(J1, se);

        p   = FastPeakFind(J2);
        col = p(1:2:end);
        row = p(2:2:end);
        nPts = numel(col);

        parfor pointnum = 1:nPts
            LB = col(pointnum) - boxR;
            RB = col(pointnum) + boxR;
            UB = row(pointnum) - boxR;
            DB = row(pointnum) + boxR;
            subarea = dataAvg1(UB:DB, LB:RB);
            if sum(subarea(:)) == 0
                datastacks1(:,:,pointnum) = subarea;
            else
                [y0, x0] = LocaGS(subarea, [1 5]);
                [m, n]   = size(subarea);
                mask     = GsMask0(x0, y0, gsMask, [n m]);
                datastacks1(:,:,pointnum) = dataAvg1(UB:DB, LB:RB) .* mask;
            end
        end

        output  = RestrGS(datastacks1, p, boxR, imgHeight0);
        Border1 = BorderDel(imgHeight0, boxR+10);
        output  = mat2gray(output .* Border1);
        datastacks2(:,:,jj) = output;
        sumdata = sumdata + output;
    end

    Border1 = BorderDel(imgHeight0, boxR+10);
    sumdata = mat2gray(sumdata .* Border1);
end

%% ========== �ֲ�������Smaincode �������ض�λ ==========
function sumdata = processSmaincode(datastacks, boxR, factor, fa)
    [imgHeight0, imgWidth0, numframes] = size(datastacks);

    x0 = 1:imgHeight0;
    y0 = 1:imgWidth0;
    x1 = (1/factor):(1/factor):imgHeight0;
    y1 = (1/factor):(1/factor):imgWidth0;
    [XX0, YY0] = meshgrid(x0, y0);
    [XX1, YY1] = meshgrid(x1, y1);

    sumdata     = zeros(imgHeight0*2*factor, imgWidth0*2*factor);
    datastacks1 = zeros(2*boxR+1, 2*boxR+1, 500);
    se          = strel('disk', fa);

    for jj = 1:numframes
        dataAvg0 = datastacks(:,:,jj);
        dataAvg1 = interp2(XX0, YY0, dataAvg0, XX1, YY1, 'cubic');
        dataAvg2 = mat2gray(dataAvg1);
        dataAvg2 = imerode(dataAvg2, se);

        Loca = FastPeakFind(dataAvg2);
        col  = Loca(1:2:end);
        row  = Loca(2:2:end);
        nPts = numel(col);

        parfor pointnum = 1:nPts
            LB = col(pointnum) - boxR;
            RB = col(pointnum) + boxR;
            UB = row(pointnum) - boxR;
            DB = row(pointnum) + boxR;
            datastacks1(:,:,pointnum) = dataAvg1(UB:DB, LB:RB);
        end

        output  = Restr(datastacks1, Loca, boxR, imgHeight0, factor);
        sumdata = sumdata + output;
    end
end
