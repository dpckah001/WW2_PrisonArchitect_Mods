# Sounds 音效资源

## 文件清单（待制作）

### ME323 运输机

#### me323_engine.wav
- 类型：环境音（Loop）
- 长度：3-5秒（循环）
- 特性：低沉、粗重的多发引擎声
- 音量：中等（-12dB）
- 参考：6 × 艾利逊发动机

### 斯图卡轰炸机

#### stuka_dive.wav
- 类型：俯冲警报声
- 长度：2秒
- 特性：高频尖啸，逐渐升高
- 音量：高（-6dB）
- 心理效果：恐怖、威胁感
- 历史背景：日尔曼尼亚之鹰（Jericho Trumpet）

#### stuka_bomb.wav
- 类型：爆炸音效
- 长度：1秒
- 特性：深沉的爆炸声 + 震撼感
- 音量：很高（-3dB）
- 频率：混合低频和冲击

### Me262 喷气战机

#### me262_jet.wav
- 类型：环境音（Loop）
- 长度：2-3秒（循环）
- 特性：尖锐的喷气发动机声
- 音量：很高（-9dB）
- 频率：高频为主
- 参考：两台 Junkers Jumo 004 喷气发动机

#### me262_mg.wav
- 类型：机炮扫射声
- 长度：0.5-1秒
- 特性：连续的机炮射击声（Rat-a-tat-tat）
- 音量：高（-8dB）
- 节奏：快速、密集
- 参考：4 × 30mm MK 108 机炮

## 技术要求

- 格式：WAV（PCM）
- 采样率：44100 Hz（或 48000 Hz）
- 位深度：16-bit
- 声道：Mono（单声道）或 Stereo（立体声）
- 无压缩

## 音效获取方式

### 选项 1：自己录制
- 使用 Audacity（开源）进行录制和编辑
- 合成器生成（需要 MIDI 合成知识）

### 选项 2：使用开源库
- Freesound.com（Creative Commons 许可）
- Zapsplat（免费音效库）
- BBC Sound Effects：https://www.bbc.co.uk/sounds/search?q=aircraft

### 选项 3：专业库
- Epidemic Sound
- Artlist
- Pond5

## 制作建议

1. **俯冲啸叫**：
   - 使用正弦波发生器
   - 从 800Hz 扫频到 2000Hz
   - 时间：2 秒
   - 添加混响和回声效果

2. **爆炸声**：
   - 使用白噪声
   - 快速衰减包络（Attack: 10ms, Decay: 500ms）
   - 低频重音（100-200Hz）

3. **喷气声**：
   - 高通滤波白噪声（2kHz 以上）
   - 加入 "whoosh" 效果
   - 环境混响

4. **机炮声**：
   - 采样真实机炮音（可从网络获取）
   - 或使用 8-bit 复古音效
   - 添加低频 "boom" 基底

## 编辑工具

- **Audacity**（推荐，开源）
- **Waveform Editor**
- **Reaper**
- **FL Studio**（需付费）
- **Adobe Audition**（需付费）

## 兼容性检查

所有音效完成后，使用 FFmpeg 统一格式：

```bash
ffmpeg -i input.mp3 -acodec pcm_s16le -ar 44100 output.wav
```

---

所有音效资源一经完成，请放入此文件夹即可自动加载。
