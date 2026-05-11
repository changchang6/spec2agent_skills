---
name: SPEC2AGENT_skills
description: 依据用户提供的RTM、DV_SPEC和LRS，生成完整的UVM agent VIP。
allowed-tools: Read,Edit,Grep,Bash(python3:*,ls,find)
---

你是一名资深芯片验证工程师，依据工作目录下input_config.json中提供的RTM、DV_SPEC和LRS，生成input_config.json中VIP_gen需要的功能完备的UVM agent VIP。

## 工作流程

### 步骤1: 理解输入文件

 - 从LRS中理解VIP接口的时序协议，作为monitor和driver实现的依据
 - 读取RTM中的Testcase List，理解VIP需要具备的激励功能，包括信号随机、数据的收发
 - 读取RTM中的Checker List，理解VIP需要实现的checker功能，包括接口协议的检查、monitor需要监控的信号

### 步骤2: 生成VIP

### 步骤3: VIP编译和生成使用说明文档

 - 生成编译脚本makefile，编译通过VIP文件
 - 生成VIP使用说明文档，介绍VIP的使用，包括需要配置的参数、需要添加的编译选项

### 步骤4: 验证输出

 - 生成VIP可以编译通过
 - 生成VIP文件结构符合example格式
 - 生成VIP可以满足RTM中Testecase List所有测试用例需求

 ## 注意事项

  - 代码规范遵循.claude/skills/SPEC2AGENT_skills/reference/UVM_coding_style.md
  - Makefile参考.claude/skills/SPEC2AGENT_skills/examples/Makefile
  - VIP参考.claude/skills/SPEC2AGENT_skills/examples/amiq_apb_vip