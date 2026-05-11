---
name: SPEC2AGENT_skills
description: 依据用户提供的RTM、DV_SPEC和LRS，生成完整的UVM agent VIP。并依据用户提供的Regmap、DUT_TOP和VIP文件，生成example UVM testbench，验证生成的VIP。
allowed-tools: Read,Edit,Grep,Bash(python3:*,ls,find)
---

你是一名资深芯片验证工程师，依据工作目录下input_config.json中提供的RTM、DV_SPEC和LRS，生成input_config.json中VIP_gen需要的功能完备的UVM agent VIP。

## 工作流程

### 步骤1: 理解输入文件

 - 从LRS中理解VIP接口的时序协议，作为monitor和driver实现的依据
 - 读取RTM中的Testcase List，理解VIP需要具备的激励功能，包括信号随机、数据的收发
 - 读取RTM中的Checker List，理解VIP需要实现的checker功能，包括接口协议的检查、monitor需要监控的信号

### 步骤2: 生成VIP

### 步骤3: 生成example TB验证VIP基本功能

如果用户在input_config.json中提供了TB_gen的相关信息，生成完整的example UVM testbench，验证生成的VIP的基本功能。

 - 搭建完整的UVM testbench，TB中使用生成的VIP
 - 生成编译脚本makefile，编译通过TB
 - 构建smoke test，进行一次基本的读写操作，检查读回值和写入值一致
 - TB默认dump波形和编译/仿真日志，dump波形用fsdb格式

### 步骤3: 生成使用说明文档

 - 介绍VIP的使用，包括需要配置的参数、需要添加的编译选项

### 步骤4: 验证输出

 - 生成VIP可以编译通过
 - 生成VIP文件结构符合参考VIP格式
 - 生成VIP可以满足RTM中Testecase List所有测试用例需求
 - 如果生成TB，跑通冒烟测试

 ## 注意事项

  - 代码规范遵循.claude/skills/SPEC2AGENT_skills/reference/UVM_coding_style.md
  - Makefile参考.claude/skills/SPEC2AGENT_skills/examples/Makefile
  - 参考VIP.claude/skills/SPEC2AGENT_skills/examples/amiq_apb_vip
  - testbench目录结构遵循.claude/skills/SPEC2TB_skills/reference/tb_dir_structure.md
  - **严禁修改VIP源文件**：复用的VIP自带完备断言检查，不应修改VIP任何源文件
  - **严禁修改设计源文件**：DUT RTL是验证对象，不应修改