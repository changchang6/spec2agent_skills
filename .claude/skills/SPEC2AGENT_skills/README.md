// 该skill（SPEC2AGENT_skills）用于：依据用户提供的RTM、DV_SPEC、LRS和TB模板，将TB中VIP的agent和if填写完整。

// skill依赖项：Python；Claude code官方文档处理skill（document-skills）

// skill执行步骤：
1.在Claude code工作目录下的input_config.json中提供RTM、DV_SPEC、LRS和TB模板文件的位置，并指定要填写的agent文件位置
2.进入claude code
3.通过/SPEC2AGENT_skills命令启动skill

// 注意事项：
// 1..skill生成的driver接口驱动时序可能和LRS中的不一致，因为AI对LRS文件中的接口时序理解能力较弱，需要人工review修改