http://blog.csdn.net/linchaolong/article/details/45202361

开发语言：Java

说明：
1.因为是使用Java语文开发的，所以是跨平台的。需要Java运行环境（https://www.oracle.com/java/index.html）。
2.支持的excel文件格式：xls、xlsx。
3.支持在单元格中插入外部文件的内容。

excel配置表：
第一行为key，第二行为描述。
第一列的值为该行table中的key。

使用说明：
1.打开config.cfg，配置相关信息。
2.在工程目录下有一个Excel2Lua.jar是用于导出lua配置表的库，还有run.bat（windows）和run.sh（Mac、Linux）两个脚本，点击导出lua配置表，也可在命令行执行java -jar Excel2Lua.jar命令生成配置表。
