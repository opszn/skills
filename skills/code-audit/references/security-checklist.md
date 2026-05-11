# Security Checklist

逐项检查，记录每项的状态：PASS / FAIL / N/A

多语言标注说明：`<!-- JS: ... | Python: ... | Go: ... -->` 表示该检查项在各语言中的对应危险模式。

## 1. 注入类漏洞

### 1.1 代码注入
- [ ] 无 `eval()` 调用（除明确测试/REPL 场景）
  <!-- JS: eval(), new Function(), setTimeout("string"), vm.runInThisContext() | Python: eval(), exec(), compile() | Go: reflect.Value.Call(), template.Must() -->
- [ ] 无 `new Function()` 动态构造函数
- [ ] 无 `setTimeout("string")` 字符串参数
- [ ] 无 `vm.runInThisContext()` / `vm.runInNewContext()` 执行用户输入

### 1.2 HTML 注入 (XSS)
- [ ] `innerHTML` 赋值使用 `escapeHtml()` 或 DOMPurify
  <!-- JS: innerHTML, outerHTML, insertAdjacentHTML, document.write, dangerouslySetInnerHTML | Python: Markup() 未正确使用 -->
- [ ] `dangerouslySetInnerHTML` 使用 DOMPurify.sanitize()
- [ ] `marked.parse()` / `markdown-it.render()` 输出经过 sanitize
- [ ] 模板字符串中的用户输入经过转义

### 1.3 命令注入
- [ ] `child_process.exec()` 不使用拼接字符串
  <!-- JS: exec(), execSync(), spawnSync(), spawn(.*, {shell: true}) | Python: os.system(), subprocess.call(shell=True), subprocess.Popen(shell=True) | Go: exec.Command(Sprintf/拼接), exec.CommandContext -->
- [ ] `spawn()` / `execFile()` 使用参数数组而非 shell 字符串
- [ ] 管道命令 `|` / `;` / `&&` 不使用未验证的变量

### 1.4 SQL 注入
- [ ] 所有 SQL 查询使用参数化语句（`?` / `$1` / ORM）
  <!-- JS: .query(模板字符串/拼接), .exec(拼接) | Python: .execute(f-string/拼接/%,format) | Go: .Query(Sprintf/拼接), .Exec(Sprintf/拼接) -->
- [ ] 无字符串拼接构造 SQL
- [ ] ORDER BY / LIMIT 等动态部分经过白名单校验

### 1.5 模板注入
- [ ] 模板引擎（EJS/Pug/Handlebars）不渲染用户可控的模板名
- [ ] 服务端渲染不执行用户输入中的 `<script>`

### 1.6 反序列化注入
- [ ] 不反序列化不可信数据
  <!-- JS: 无直接风险（JSON.parse 安全） | Python: pickle.load(), yaml.load(无 Loader), marshal.loads(), __reduce__ | Go: json.Unmarshal(不可信数据), xml.Unmarshal, gob.Decode -->

## 2. 路径安全

### 2.1 路径遍历
- [ ] 所有文件读取使用 `path.resolve()` 规范化路径
  <!-- JS: fs.readFile(path.join(userInput)), path.resolve, fs.createReadStream | Python: open(user_input), os.path.join(user_input) | Go: os.Open(path), ioutil.ReadFile, filepath.Join -->
- [ ] 文件访问前校验 `resolvedPath.startsWith(allowedDir)`
- [ ] 不使用 `path.includes()` 做路径安全校验（可绕过）
- [ ] 符号链接处理：使用 `fs.realpathSync()` 解析真实路径

### 2.2 任意文件操作
- [ ] `fs.readFile/WriteFile` 的文件路径不来自未验证的用户输入
- [ ] `shell.openPath()` 的路径在白名单目录内
- [ ] 文件上传有类型校验和大小限制
- [ ] 文件下载无 SSRF（不请求内网地址）

## 3. 认证与授权

### 3.1 凭据管理
- [ ] 无硬编码密码/API Key/Token/Secret
  <!-- 跨语言: grep -rn 'password\s*=\s*["\x27]', 'secret\s*=\s*["\x27]', 'api_key\s*=\s*["\x27]', 'AKIA[0-9A-Z]{16}' -->
- [ ] 使用环境变量和密钥管理服务（不在代码中存储）
- [ ] `.env` 文件在 `.gitignore` 中
- [ ] 无 `.env` / `.credentials` / `secrets.*` 文件提交到仓库

### 3.2 会话与 Token
- [ ] 会话 Token 使用加密安全的随机数生成
  <!-- JS: crypto.randomBytes | Python: secrets.token_urlsafe | Go: crypto/rand -->
- [ ] Token 有过期机制
- [ ] 无 Token 在 URL 中传递
- [ ] 敏感操作需要重新认证

### 3.3 访问控制
- [ ] 所有 API 端点有认证中间件
- [ ] 角色/权限校验在服务器端执行（不信任前端）
- [ ] 无水平越权（用户 A 不能访问用户 B 的数据）
- [ ] 管理端点有额外的权限校验

## 4. 数据保护

### 4.1 传输安全
- [ ] 生产环境使用 HTTPS
- [ ] 无 `rejectUnauthorized: false` 配置
- [ ] API 请求使用正确的证书验证

### 4.2 存储安全
- [ ] 密码使用 bcrypt/argon2 哈希存储（非明文、非 MD5/SHA1）
  <!-- JS: bcrypt, argon2 | Python: passlib, bcrypt | Go: golang.org/x/crypto/bcrypt -->
- [ ] 敏感数据（PII）加密存储
- [ ] 日志中不打印密码、Token、完整信用卡号

### 4.3 数据验证
- [ ] 所有外部输入有类型校验和范围限制
- [ ] JSON Schema / Zod / Joi 等验证库用于 API 输入
- [ ] 文件大小、数量、频率有限制

## 5. 安全配置

### 5.1 Content Security Policy (CSP)
- [ ] Web 项目设置 CSP 响应头
- [ ] CSP 限制 script-src、style-src、img-src
- [ ] 不使用 `unsafe-inline`（或仅在有 nonce 时使用）
- [ ] 不使用 `unsafe-eval`

### 5.2 Electron 安全
- [ ] `contextIsolation: true`
- [ ] `nodeIntegration: false`
- [ ] `sandbox: true`（推荐）
- [ ] `webSecurity: true`（不关闭）
- [ ] `setWindowOpenHandler` 阻止意外导航
- [ ] `will-navigate` 事件处理

### 5.3 CORS
- [ ] 生产环境 CORS 限制为特定域名
- [ ] 不使用 `Access-Control-Allow-Origin: *`
- [ ] CORS 预检请求正确处理

### 5.4 SSRF 防护
- [ ] 用户可控 URL 的请求有内网地址过滤
  <!-- JS: fetch(userUrl), axios.get(userUrl), http.request(userUrl) | Python: requests.get(user_input), urllib.request | Go: http.Get(userInput), http.Client.Do -->
- [ ] 不跟随重定向到内网地址
- [ ] 不使用无限制的 URL 白名单外的请求

## 6. 加密安全

### 6.1 弱加密
- [ ] 不使用 MD5/SHA1 做安全哈希（仅用于校验完整性）
  <!-- JS: crypto.createHash('md5') | Python: hashlib.md5() | Go: crypto/md5 -->
- [ ] 不使用 DES/RC4 等弱加密算法
- [ ] 不使用 Math.random() 生成安全相关的随机数
  <!-- JS: Math.random() → 改用 crypto.randomBytes | Python: random → 改用 secrets | Go: math/rand → 改用 crypto/rand -->

### 6.2 JWT 配置
- [ ] JWT secret 不使用默认值或弱密码
- [ ] JWT 算法不设置为 `none`
- [ ] JWT 有合理的过期时间

## 7. 依赖安全 (SAST)

审计前自动检测并运行以下工具，结果并入审计报告：

- [ ] **Node.js**: `npm audit --omit=dev`（有 package-lock.json 时）
- [ ] **Python**: `pip-audit` 或 `safety check`（有 requirements.txt 时）
- [ ] **Go**: `govulncheck ./...` 或 `go vet ./...`（有 go.mod 时）
- [ ] **Rust**: `cargo audit`（有 Cargo.lock 时）
- [ ] **Java/Maven**: `mvn dependency-check:check`（有 pom.xml 时）

依赖管理检查：
- [ ] 依赖版本锁定文件存在（package-lock.json / go.sum / Pipfile.lock / Cargo.lock）
- [ ] 无来路不明的第三方包（检查包作者和下载量）
- [ ] 依赖无明显过期（超过 2 年未更新的主要依赖需标注）

## 8. 日志与监控

- [ ] 错误日志不泄露敏感信息（密码、Token、完整 PII）
  <!-- 跨语言: grep -rn 'console.log.*password\|log.*token\|print.*secret\|log.*key' -->
- [ ] 生产环境不输出调试信息
- [ ] 安全事件（登录失败、权限拒绝）有审计日志
- [ ] 异常有上报机制（非仅 console.log / print）
- [ ] 无空 catch 块吞异常
  <!-- JS: catch(e) {} | Python: except: pass -->
