---
layout: post
title: nRF52-QA-芯片EOS-ESD损坏验证
date: 2022-03-24
category: nRF52-QA
tags:
- nRF52x
- EOS
- ESD
- 钳位二极管
last_modified_at: 2022-03-24T12:57:42-05:00
# excerpt_separator:  <!--more-->
---

#### 一、芯片EOS/ESD损坏初步判定
1. 测试芯片 VDD 与 GND 之间电阻：万用表打到电阻挡位，红表笔接VDD，黑表笔接GND，电阻 13MΩ左右，则初步判断芯片 OK 。
2. 测试芯片 VDD 与 GND 之间电阻：万用表打到电阻挡位，红表笔接VDD，黑表笔接GND，电阻 1MΩ以下，则初步判断芯片有ESD/EOS损伤 。


#### 二、芯片EOS/ESD损坏问题定位
1. 万用表打到测量二极管挡位，依次测试每个GPIO口钳位二极管压降（不包括晶振、天线和VDD口）
2. GPIO与GND之间钳位二极管测试：万用表打到二极管挡位->万用表红表笔接GND，万用表黑表笔接GPIO口，读取二极管压降，并记录
3. GPIO与VDD之间钳位二极管测试：万用表打到二极管挡位->万用表黑表笔接VDD，万用表红表笔接GPIO口，读取二极管压降，并记录
4. 钳位二极管压降，正常数值范围：0.5-0.7V左右
5. 钳位二极管压降，异常数值范围：小于0.4V
