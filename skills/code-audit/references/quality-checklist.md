# Quality Checklist

逐项检查，记录每项的状态：PASS / FAIL / N/A

## 1. 死代码检测

### 1.1 未使用的函数
- [ ] 查找定义但无调用的函数：`grep -n 'function \w\+' --include='*.js' --include='*.ts' . | while read line; do func=$(echo "$line" | grep -oP '(?<=function )\w+'); if func && ! grep -q "$func(" --include='*.js' --include='*.ts' -r . 2>/dev/null | grep -v "function $func" | grep -v "// $func" | grep -q .; then echo "可能未使用: $line"; fi; done`
- [ ] 导出的模块是否被 import（检查 `module.exports` / `export` 的使用）
- [ ] 事件监听器是否有对应的移除（`removeEventListener` / `removeAllListeners`）

### 1.2 未使用的变量
- [ ] 声明但从未读取的变量
- [ ] 赋值但从未使用的变量
- [ ] 注释掉的代码块（超过 5 行）

### 1.3 未使用的依赖
- [ ] package.json / requirements.txt 中的包是否在代码中被 import/require
- [ ] 重复功能的包（如 lodash + underscore, moment + dayjs）

## 2. 代码重复

- [ ] 相同逻辑在 2 个以上文件中出现（>10 行相同/相似代码块）
- [ ] 复制粘贴的错误（变量名忘了改）
- [ ] 重复的错误处理模式（应该提取为中间件/工具函数）

## 3. 命名一致性

### 3.1 命名风格
- [ ] 变量/函数命名统一 camelCase（JS/TS）或 snake_case（Python）
- [ ] 常量统一 UPPER_SNAKE_CASE
- [ ] 类名统一 PascalCase
- [ ] 无混合风格（如同一个文件中既有 `get_data` 又有 `getData`）

### 3.2 缩写一致性
- [ ] 同一概念在整个项目中使用同一缩写（如 `msg` vs `message` vs `msgText`）
- [ ] 缩写不超过 3-4 个字母，否则不如写全称

### 3.3 布尔命名
- [ ] 布尔变量/函数以 `is` / `has` / `can` / `should` 开头
- [ ] 非布尔函数不以 `is` 开头

## 4. 错误处理

### 4.1 catch 质量
- [ ] 无空 `catch {}`（应至少 console.error 或记录日志）
- [ ] catch 中不吞掉错误（应 re-throw 或返回错误状态）
- [ ] async/await 有 try/catch 保护
- [ ] Promise 链有 `.catch()` 终节点

### 4.2 错误传播
- [ ] 底层错误能传播到调用方
- [ ] 错误消息包含足够调试信息（文件名、操作、原始错误）
- [ ] 不将内部错误详情暴露给终端用户

### 4.3 优雅降级
- [ ] 非关键功能失败不影响主流程
- [ ] 缓存失效时有 fallback
- [ ] 网络请求失败有重试或超时

## 5. 文件大小与复杂度

### 5.1 大文件
- [ ] 单文件 < 500 行（推荐）
- [ ] 单文件 < 1000 行（上限）
- [ ] 单文件 > 1500 行（必须拆分）
- [ ] 单函数 < 50 行（推荐）
- [ ] 单函数 > 100 行（需拆分）

### 5.2 圈复杂度
- [ ] 函数中 `if/else/switch/for/while/?.` 总数 < 10
- [ ] 嵌套层级 < 4（用 early return 替代深层嵌套）
- [ ] 单个函数无超过 3 层条件嵌套

### 5.3 函数参数
- [ ] 函数参数 <= 3 个（推荐）
- [ ] 函数参数 > 5 个（应使用 options 对象）
- [ ] 无超过 10 个参数的函数

## 6. 同步阻塞

### 6.1 Node.js 主线程
- [ ] IPC 处理器中不使用 `*Sync` 方法
- [ ] 应用启动时允许同步读取配置，但运行时改用异步
- [ ] 大文件读取使用流式处理

### 6.2 前端主线程
- [ ] 无同步 XHR 请求
- [ ] 大数据处理使用 Web Worker 或分批处理
- [ ] 动画/渲染不阻塞事件循环

## 7. 性能

### 7.1 算法复杂度
- [ ] 无 O(n²) 或更差的不必要循环（应该用 Map/Set 优化查找）
- [ ] 数组遍历中无嵌套数组遍历（除非 n 很小）
- [ ] 频繁查找使用 Map/Set 而非 Array.find()

### 7.2 缓存
- [ ] 重计算结果有缓存（memoize）
- [ ] 文件状态有 mtime 缓存
- [ ] DOM 查询结果缓存（不重复 querySelector）

### 7.3 防抖与节流
- [ ] 搜索输入有 debounce（200-500ms）
- [ ] 窗口 resize 有 throttle
- [ ] 滚动事件有 throttle
- [ ] 高频事件（mouse move、input）有限流

### 7.4 渲染
- [ ] 图表重绘前 destroy 旧实例
- [ ] 列表渲染使用虚拟列表（>100 项）
- [ ] 无不必要的状态更新导致全量重渲染

## 8. 代码风格

- [ ] 一致的空格/缩进（2 空格或 4 空格，项目内统一）
- [ ] 一致的引号风格（单引号或双引号）
- [ ] 一致的尾逗号风格
- [ ] 无 console.log 在生产代码（除调试用途）
- [ ] TODO/FIXME/HACK 注释有对应的 issue 编号或日期
- [ ] 魔法数字有命名常量
