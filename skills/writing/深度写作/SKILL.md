---
name: 深度写作
description: "Write publishable deep-thinking articles from real experiences. Supports agent research, AI dehumanization review, voice profile learning, and multi-phase revision. Outputs to markdown, clipboard, or Yuque."
version: 2.0.0
license: MIT
author: opszn
user-invocable: true
tags: [writing, article, blog, deep-thinking, content-creation, chinese]
compatibility: [claude-code]
---

# 深度写作 / Deep Writing

Write publishable deep-thinking articles from real experiences and observations.

## Parameters

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| 话题 (topic) | Yes | - | Article core topic or trigger event |
| 风格 (style) | No | 深度分析 | 深度分析/行业观察/技术反思/个人感悟 |
| 目标读者 (audience) | No | 技术从业者 | Target audience |
| 字数 (word count) | No | 4000-6000 | Target word count range |
| `--output` | No | markdown | markdown / clipboard / yuque |
| `--publish yuque` | No | - | Explicitly publish to Yuque (requires Yuque MCP) |
| `--voice` | No | - | Provide writing sample file to build voice profile |
| `--no-review` | No | - | Skip review, output draft directly |

## Examples

```bash
/深度写作 AI依赖悖论
/深度写作 话题=Vibe Coding的风险 风格=行业观察
/深度写作 自动化运维的陷阱 --output clipboard
/深度写作 话题=AI工具选择 风格=技术反思 --publish yuque
```

## Workflow

### Step 0: Load Voice Profile (Optional)

Check if `.claude/writing-voice.json` exists:
- Exists: Load user's voice preferences (sentence length, paragraph style, tone, avoided words)
- Not exists: Guide user to provide 2-3 of their own writing samples to build a profile

Voice profile structure:
```json
{
  "voiceProfile": {
    "avgSentenceLength": "medium",
    "paragraphStyle": "concise",
    "tone": "calm-analytical",
    "firstPerson": true,
    "avoidedWords": ["彰显了", "引发了广泛关注"],
    "preferredTransitions": ["实际上", "回看当时"]
  }
}
```

### Step 1: Understand Topic & Trigger Event

- Confirm with user: What triggered this topic? Is there a real experience/case?
- Real cases are the most powerful part of an article — always prioritize them
- If user has no specific case, ask guiding questions

### Step 2: Deep Research (Launch Agent)

Launch a general-purpose Agent for background research, covering:

1. **Historical Analogy**: 3-5 historical precedents with academic/authoritative backing
2. **Current Industry Observation**: Hacker News, Reddit, authoritative media
3. **Theoretical Framework**: Layered models, degradation matrices, irreplaceable capability lists
4. **Practical Advice**: Individual, team, tool/system levels

### Step 3: Article Structure Design

Design structure based on research, confirm with user before writing. Recommended:

```
Hook (real case, direct entry) → Historical Echo → What's Happening → Framework → Deep Risks → What to Do → Conclusion
```

### Step 4a: Draft

Write the draft per confirmed structure, save to `writing-drafts/draft-{date}-v1.md`:

```bash
mkdir -p writing-drafts
DRAFT_FILE="writing-drafts/draft-$(date +%Y%m%d-%H%M%S)-v1.md"
```

**Writing Principles**:
1. **Case-driven**: Each argument starts with a concrete case, not abstract claims
2. **Data bonus**: Citation counts, report data, timelines
3. **No sensationalism**: Avoid "AI will destroy humanity" exaggeration; keep calm narrative
4. **Self-reflection**: Honestly write about your own influence
5. **Correct one-sidedness**: Review arguments in conclusion for blind spots
6. **Golden quote ending**: Last sentence should be independently shareable
7. **Chinese language**: Full article in Chinese

### Step 4b: Review (skip with `--no-review`)

Graded review of the draft. Load `references/ai-patterns-zh.md` as fingerprint reference:

| Severity | Checks |
|----------|--------|
| Critical | Arguments without case support, data without sources, conclusions without logic |
| Significant | Paragraphs >200 chars, awkward transitions, repetitive expressions, AI fingerprint hits |
| Minor | Punctuation inconsistency, imprecise wording, format inconsistency |

**AI Dehumanization**: Scan Chinese AI writing fingerprint patterns:

| Pattern | Example | Suggestion |
|---------|---------|------------|
| Over-emphasis | "彰显了"、"里程碑意义" | Remove modifiers, state directly |
| Empty engagement | "引发广泛关注" | Add concrete data or citations |
| Mechanical parallelism | "不仅...更是...也是..." | Simplify to single sentence |
| Modifier stacking | "作为一个...的...的..." | Break into shorter sentences |
| Vague conclusions | "值得深思" | Give specific action items |
| Excessive hedging | "仅代表个人观点" | Delete, state directly |
| Template openings | "随着...的发展" | Open with concrete scene |

Show review results item by item. Confirm fixes, then generate v2.

### Step 4c: Polish

Final polish before publication:
- Is the title compelling? (Can it be shared independently?)
- Do the first 3 paragraphs hook the reader?
- Is the closing golden quote sharp?
- Is the rhythm right? (tension → release → tension)

Generate final version.

### Step 5: Output

Output based on `--output` parameter:

| Method | Behavior |
|--------|----------|
| `markdown` (default) | Save as `.md` file to `writing-drafts/` |
| `clipboard` | Copy to clipboard |
| `yuque` | Publish to Yuque (requires Yuque MCP) |

**Yuque Publishing** (only when `--publish yuque` and Yuque MCP is detected):
1. Use `skylark_user_book_list` to get user's available knowledge bases
2. Ask user which knowledge base to publish to (no hardcoded defaults)
3. Use `skylark_doc_create` to create the document
4. Return the document link

### Step 6: Output Summary

Output to user:
- Article title and output location/link
- Core arguments (within 3 sentences)
- Golden quotes (1-2 sentences)
- Word count

---

## Quality Checklist

- ✅ Has real cases (not abstract argumentation)
- ✅ Has historical analogy (not only about the present)
- ✅ Has theoretical framework (not just observations)
- ✅ Has practical advice (not just problems)
- ✅ Has self-reflection (not just criticizing others)
- ✅ Has data/citation support (not just gut feeling)
- ✅ Conclusion has been reviewed and refined (not first-draft conclusion)
- ✅ Passes AI dehumanization review (no obvious AI writing fingerprints)

---

## Notes

1. **Use Agent for research**: Deep research must launch an Agent for parallel search
2. **Structure before content**: Confirm article structure before writing full text
3. **Conclusion must be reviewed**: After first-draft conclusion, actively check for one-sidedness
4. **Respect user judgment**: If user disagrees with an argument, defer to the user
5. **No hardcoded platforms**: Default to markdown output; publishing platforms chosen by user
