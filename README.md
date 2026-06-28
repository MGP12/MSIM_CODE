1. MainCode1.m — 第一步：点阵预处理与亚区域重构
作用：把 DMD 扫描得到的多帧点阵原始图，处理成“每帧重构图”和“全部帧叠加图”。

输入：用户手动选一个多页 TIFF 堆栈（一次扫描的多帧点阵图）。

主要步骤（每帧循环）：

巴特沃斯低通滤波，去高频噪声
形态学开运算 + FastPeakFind 自动找每个光斑位置
以每个峰为中心截取亚区域（半径 boxR=6）
用 LocaGS 做高斯拟合，GsMask0 生成掩膜，只保留光斑核心
RestrGS 把各亚区域按原坐标贴回，重构成一整帧图
所有帧叠加 → 得到宽场式叠加图
输出：

datastacks2.mat：每帧重构后的 3D 堆栈（供 Smaincode 使用）
一张 亚区域叠加图 .tif
特点：单文件、交互式（弹窗选文件），处理一层/一组数据。

2. Smaincode.m — 第二步：亚像素重定位
作用：在 MainCode1 结果基础上，进一步提高定位精度，生成最终重定位图像。

输入：load datastacks2（MainCode1 保存的中间结果）。

主要步骤（每帧循环）：

对重构帧做三次样条插值（factor=1 时尺寸不变，为后续定位做准备）
腐蚀 + FastPeakFind 再次寻峰
截取亚区域，Restr 按 2× 坐标 贴到更大画布上（亚像素重分配）
56 帧全部叠加 → 得到最终重定位图
输出：

一张 亚像素重定位图 .tif（尺寸约为原图的 2 倍）
特点：必须先跑 MainCode1，单独运行、处理一组数据。

3. BatchProcess_PointArray.m — 批量自动化
作用：把 MainCode1 + Smaincode 的逻辑写进一个函数，自动遍历多层文件夹，无需手动选文件。

输入：
inputRoot\<层号>\*.tif
例如 按层整理\1\、按层整理\2\ … 每层 56 个独立 TIFF。

对每一层自动完成：

processMainCode1Layer → 等同 MainCode1（读文件夹内多个 tif，而非多页堆栈）
processSmaincode → 等同 Smaincode
输出（按类型分文件夹）：
01_亚区域堆栈_mat
每层 datastacks2.mat
02_亚区域叠加图
MainCode1 叠加结果
03_亚像素重定位图
Smaincode 最终结果
处理日志.txt
成功/失败记录
特点：无人值守批量处理（如 157 层），逻辑与另两个脚本一致，只是输入方式和输出组织不同。
