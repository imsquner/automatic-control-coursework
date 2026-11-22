# 自动控制原理下综合实践

用于整理状态空间课程实践的报告模板和可复跑的软件环境检查。

- [资料索引与填报顺序](docs/material-index.md)是从模板到交稿的入口。
- [课程要求与宣讲说明](docs/course-requirements.md)汇总字数、版式、装订、评分与答辩要求。
- [Word 报告模板](docs/report-template.docx)提供封面、目录、正文、图表位置与评定表版式。
- [报告写作与验收](docs/report-guide.md)给出报告结构、引用和提交前检查项。
- [MATLAB 与 Simulink 环境验算](docs/matlab-simulink-smoke-test.md)包含完整的 PowerShell 批处理命令。算例为热水自然冷却。

在仓库根目录用 Windows PowerShell 运行 `.\scripts\verify-matlab.ps1`。独立算例的完整命令和排查说明也保留在文档中。

环境验算曾在 Windows 上用 MATLAB R2022a 实跑通过。运行需要 MATLAB、Control System Toolbox 和 Simulink。实际课程的任务书、分析计算和仿真结果在提交版报告中由撰写人填写。

## 课程原表与个人报告

- [本人报告公开副本](docs/personal-report.docx)保留封面、身份信息和报告正文，任务书页留有装订位置。
- [课程格式资料包](docs/course-format-materials.zip)收录课程封面、统一书写格式、成绩评定表和书面要求四个源文件。
