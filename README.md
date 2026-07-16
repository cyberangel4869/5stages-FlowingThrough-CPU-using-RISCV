# 5stages-FlowingThrough-CPU-using-RISCV
基于RISC-V指令集的五段流水CPU设计。已实现R-type，I-type类指令和分支，跳转，直接寻址与简介寻址等功能，自带简单的2bit深度分支预测

## 顶层结构框图
```mermaid
flowchart TB
    subgraph CPU["CPU 顶层模块"]
        
        subgraph IF["IF 阶段 (取指)"]
            PC_BTB["PC_BTB<br/>(PC和BTB)"]
            ROM["ROM<br/>(指令存储器)"]
            
            PC_BTB -->|PC, PC_add4| ROM
        end
        
        subgraph IF_ID["IF-ID 流水线寄存器"]
            IF_ID_regs["IF_ID_regs<br/>(时钟上升沿锁存)"]
        end
        
        subgraph ID["ID 阶段 (译码)"]
            IDU["InstructionDecoder<br/>(指令译码器)"]
            RF["RegisterFile<br/>(寄存器文件)"]
            predicPCsub4["SUBB4<br/>(PC预测计算)"]
            
            IDU -->|rs1, rs2| RF
            predicPCsub4 -->|PC_predict| JCU
        end
        
        subgraph ID_EX["ID-EX 流水线寄存器"]
            ID_EX_regs["ID_EX_regs<br/>(时钟上升沿锁存)"]
        end
        
        subgraph EX["EX 阶段 (执行)"]
            rs1_data_MUX["rs1_data_MUX<br/>(数据前传选择)"]
            rs2_data_MUX["rs2_data_MUX<br/>(数据前传选择)"]
            A_select["A_select MUX<br/>(操作数A选择)"]
            B_select["B_select MUX<br/>(操作数B选择)"]
            ALU["ALU<br/>(算术逻辑单元)"]
            JCU["JumpCtrlUnion<br/>(跳转控制单元)"]
            PC_sub4["SUBB4<br/>(PC减4)"]
            jumpPCsub4["SUBB4<br/>(跳转PC计算)"]
            
            rs1_data_MUX -->|EX_rs1_update_data| A_select
            rs2_data_MUX -->|EX_rs2_update_data| B_select
            A_select -->|EX_ALU_data_A| ALU
            B_select -->|EX_ALU_data_B| ALU
            ALU -->|EX_Result, EX_Zero| JCU
            PC_sub4 -->|EX_PC| A_select
            jumpPCsub4 -->|jump_PC| PC_BTB
        end
        
        subgraph EX_MEM["EX-MEM 流水线寄存器"]
            EX_MEM_regs["EX_MEM_regs<br/>(时钟上升沿锁存)"]
        end
        
        subgraph MEM["MEM 阶段 (访存)"]
            RAM["RAM<br/>(数据存储器)"]
        end
        
        subgraph MEM_WB["MEM-WB 流水线寄存器"]
            MEM_WB_regs["MEM_WB_regs<br/>(时钟上升沿锁存)"]
        end
        
        subgraph WB["WB 阶段 (写回)"]
            WBCL["WritebackControlLogic<br/>(写回控制逻辑)"]
        end
        
        subgraph GlobalCtrl["全局控制单元"]
            FCU["ForwardingCtrlUnion<br/>(数据前传控制单元)"]
            BHT["BHT<br/>(分支历史表)"]
        end
        
        %% 流水线数据流连接
        IF -->|IF_instruction, IF_PC_add4| IF_ID
        IF_ID -->|ID_instruction, ID_PC_add4| ID
        ID -->|ID数据和控制信号| ID_EX
        ID_EX -->|EX数据和控制信号| EX
        EX -->|EX结果和控制信号| EX_MEM
        EX_MEM -->|MEM数据和控制信号| MEM
        MEM -->|MEM数据和结果| MEM_WB
        MEM_WB -->|WB数据| WB
        
        %% 反馈控制路径
        WB -->|we, waddr, wdata| RF
        EX -->|jump, is_JBtype, clean, PC_update, jump_dist| IF
        
        %% 数据前传路径
        EX -->|EX_instruction| FCU
        EX_MEM -->|MEM_instruction, MEM_Result| FCU
        MEM_WB -->|WB_instruction, WB_Result| FCU
        MEM -->|MEM_LOAD_data| FCU
        FCU -->|data1_update, data2_update,<br/>rs1_update_data, rs2_update_data, Bubble| EX
        
        %% BHT连接
        EX -->|is_JBtype, jump| BHT
        BHT -->|serch_en| PC_BTB
        
        %% 全局控制信号标注
        PC_BTB -.->|Bubble, PC_update, serch_en,<br/>jump_PC, jump_dist| IF
        JCU -.->|jump, is_JBtype, PC_update,<br/>clean, jump_dist| PC_BTB
        
    end
    
    %% 外部接口
    clk["clk (时钟)"] --> CPU
    rst_n["rst_n (复位)"] --> CPU
    
    %% 样式定义
    classDef stage fill:#e1f5fe,stroke:#01579b,stroke-width:2px
    classDef regs fill:#fff3e0,stroke:#e65100,stroke-width:2px
    classDef control fill:#f3e5f5,stroke:#4a148c,stroke-width:2px
    classDef mem fill:#e8f5e8,stroke:#1b5e20,stroke-width:2px
    
    class IF,ID,EX,MEM,WB stage
    class IF_ID,ID_EX,EX_MEM,MEM_WB regs
    class GlobalCtrl control
    class ROM,RAM mem
```

### 结构图说明
#### 1. 五级流水线结构
IF阶段：PC_BTB生成PC地址，ROM读取指令

ID阶段：指令译码、寄存器读取、PC预测计算

EX阶段：数据前传、操作数选择、ALU运算、跳转控制

MEM阶段：数据存储器读写

WB阶段：写回数据选择和控制

#### 2. 流水线寄存器
每个阶段之间通过D触发器组隔离（IF-ID、ID-EX、EX-MEM、MEM-WB）

确保时序正确，避免数据冲突

#### 3. 关键控制路径
数据前传：通过FCU检测数据冒险，将EX/MEM/WB阶段的结果前传到EX阶段

跳转控制：JCU生成跳转信号，反馈到IF阶段修改PC

分支预测：BHT提供分支预测信息，配合BTB优化取指

#### 4. 全局控制信号
Bubble：流水线暂停

clean：指令冲刷

we/waddr/wdata：寄存器写回控制

data1_update/data2_update：数据前传使能

## 分支预测
分支预测由BTB和BHT配合完成
### PC_BTB 模块结构
#### 1.1 模块组成
```mermaid
flowchart TB
    subgraph PC_BTB["PC_BTB 模块"]
        PC_Reg["PC寄存器<br/>(32位)"]
        BTB_MEM["BTB存储阵列<br/>256项 × {tag[21:0], target[31:0]}"]
        Index_Gen["索引生成<br/>PC[9:2]"]
        Tag_Gen["标签生成<br/>PC[31:10]"]
        Hit_Detect["命中检测<br/>tag == PC_tag && target != 0"]
        PC_Update_Logic["PC更新逻辑<br/>(组合逻辑)"]
        PC_add4_Gen["PC+4生成"]
        
        PC_Reg --> Index_Gen
        PC_Reg --> Tag_Gen
        Index_Gen --> BTB_MEM
        Tag_Gen --> Hit_Detect
        BTB_MEM --> Hit_Detect
        Hit_Detect --> PC_Update_Logic
        PC_Update_Logic --> PC_Reg
        PC_Reg --> PC_add4_Gen
        
        PC_Update --> PC_Update_Logic
        serch_en --> PC_Update_Logic
        jump_PC --> PC_Update_Logic
        jump_dist --> PC_Update_Logic
        Bubble --> PC_Reg
    end
```
#### 1.2 关键数据结构
* BTB存储：256项直接映射缓存

    * `tag[21:0]`：存储PC的高22位用于地址匹配

    * `target[31:0]`：存储分支跳转的目标地址

* 索引计算：`PC[9:2]`（8位地址，256项）

* 命中条件：`tag[index] == PC[31:10] && target[index] != 0`

#### 1.3 PC更新逻辑
```iverilog
next_PC = PC_update ? jump_dist :                    // ① 分支实际跳转
          (serch_en && BTB_hit) ? target[index] :    // ② BTB预测跳转
          PC + 3'd4;                                 // ③ 顺序执行
```
优先级：分支实际跳转 > BTB预测跳转 > 顺序执行

### BHT 模块结构
#### 2.1 状态机设计
使用2位饱和计数器实现4状态分支预测：

| 状态编码 | 状态含义 | 预测输出 |
|:-------:|:-------:|:-------|
| 00 |	强不跳（Strongly Not Taken）|	0 |
| 01 |	弱不跳（Weakly Not Taken） |	0 |
| 10 |	弱跳转（Weakly Taken） |	1 |
| 11 |	强跳转（Strongly Taken） |	1 |
#### 2.2 状态转移图
```mermaid
stateDiagram-v2
    [*] --> 弱不跳: 复位
    
    强不跳 --> 弱不跳: jump=1(预测错误)
    强不跳 --> 强不跳: jump=0(预测正确)
    
    弱不跳 --> 强不跳: jump=0(预测正确)
    弱不跳 --> 弱跳转: jump=1(预测错误)
    
    弱跳转 --> 弱不跳: jump=0(预测错误)
    弱跳转 --> 强跳转: jump=1(预测正确)
    
    强跳转 --> 强跳转: jump=1(预测正确)
    强跳转 --> 弱跳转: jump=0(预测错误)
    
    note right of 弱不跳: 初始状态
    note left of 强不跳: 预测不跳
    note right of 强跳转: 预测跳转
```
#### 2.3 更新条件
* 仅在 `is_JBtype=1` 时更新状态（跳转类指令）

* 根据实际 `jump` 信号更新计数器状态

* 状态值向跳转/不跳转方向饱和变化

### 协同工作流程
#### 3.1 预测阶段（IF阶段）
```mermaid
sequenceDiagram
    participant PC as PC寄存器
    participant BHT as BHT
    participant BTB as BTB存储
    participant ALU as ALU/JCU
    
    Note over PC,ALU: 预测阶段（取指时）
    PC->>BHT: 当前PC
    BHT-->>PC: serch_en(预测结果)
    PC->>BTB: 用PC[9:2]查表
    BTB-->>PC: target[index]
    alt serch_en=1 && BTB_hit=1
        PC->>PC: PC = target[index]
    else serch_en=0 或 BTB未命中
        PC->>PC: PC = PC + 4
    end
```
#### 3.2 更新阶段（EX阶段）
```mermaid
sequenceDiagram
    participant EX as EX阶段
    participant JCU as JumpCtrlUnion
    participant BHT as BHT
    participant BTB as BTB存储
    participant PC as PC寄存器
    
    Note over EX,PC: 更新阶段（执行时）
    EX->>JCU: 指令信息
    JCU-->>EX: jump, is_JBtype, jump_dist
    
    alt is_JBtype=1 (跳转指令)
        EX->>BHT: jump, is_JBtype
        BHT->>BHT: 更新2位计数器状态
        
        alt jump=1 (实际跳转)
            EX->>BTB: jump_PC, jump_dist
            BTB->>BTB: 更新BTB表项
            EX->>PC: PC_update=1
            PC->>PC: PC = jump_dist
        end
    end
```
#### 3.3 完整流水线流程
```mermaid
flowchart LR
    subgraph IF["IF阶段"]
        A1[读取PC]
        A2[BHT预测]
        A3[BTB查表]
        A4[生成next_PC]
    end
    
    subgraph ID["ID阶段"]
        B1[指令译码]
        B2[读取寄存器]
    end
    
    subgraph EX["EX阶段"]
        C1[ALU计算]
        C2[JCU判断]
        C3[更新BHT]
        C4[更新BTB]
    end
    
    IF -->|取指| ID
    ID -->|执行| EX
    EX -->|反馈| IF
    
    A2 -.->|serch_en| A4
    A3 -.->|BTB_hit, target| A4
    C2 -.->|jump, is_JBtype| C3
    C2 -.->|jump_PC, jump_dist| C4
    C3 -.->|更新BHT状态| A2
    C4 -.->|更新BTB表项| A3
```
### 性能优化与关键特点
#### 4.1 延迟优化
* 组合逻辑PC更新：next_PC使用assign组合逻辑，减少时钟周期延迟

* Bubble控制：暂停时PC不更新，保持流水线稳定性

* 两级预测：BHT提供方向预测，BTB提供目标地址

#### 4.2 预测准确率提升
* 2位饱和计数器：对分支模式有一定容忍度，避免频繁震荡

* 仅在跳转指令时更新：减少不必要的状态变化

* 强/弱区分：提供置信度信息，避免单次误判导致预测反转

#### 4.3 错误恢复
* `PC_update`优先级最高：当实际跳转时，直接使用jump_dist覆盖预测结果

* `clean`信号配合：预测错误时冲刷流水线，恢复正确PC
