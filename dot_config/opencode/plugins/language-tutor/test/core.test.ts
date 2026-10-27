import { describe, expect, test } from "bun:test"
import {
  DEFAULT_SETTINGS,
  buildReviewPrompt,
  extractJson,
  normalizeSettings,
  parseModelChoice,
  parseReviewResult,
  shouldSkipCheck,
  truncate,
} from "../src/core"

describe("settings", () => {
  test("defaults are English -> Simplified Chinese with checking on", () => {
    expect(normalizeSettings(undefined)).toEqual(DEFAULT_SETTINGS)
  })

  test("accepts legacy on/off and a model string", () => {
    expect(
      normalizeSettings({
        learning: "ja",
        native: "en",
        check: "off",
        model: "anthropic/claude-sonnet-5-5",
      }),
    ).toEqual({
      learning: "ja",
      native: "en",
      check: false,
      model: { providerID: "anthropic", id: "claude-sonnet-5-5" },
    })
  })

  test("parses a model reference at the first slash", () => {
    expect(parseModelChoice("openrouter/vendor/model")).toEqual({
      providerID: "openrouter",
      id: "vendor/model",
    })
    expect(parseModelChoice("nonsense")).toBeUndefined()
  })
})

describe("prompt heuristics", () => {
  test("skips commands, code fences, and very short prompts", () => {
    expect(shouldSkipCheck("/lang-tu")).toBe(true)
    expect(shouldSkipCheck("!git status")).toBe(true)
    expect(shouldSkipCheck("fix this\n```ts\nconst x = 1\n```")).toBe(true)
    expect(shouldSkipCheck("hello")).toBe(true)
    expect(shouldSkipCheck("a b c")).toBe(true)
  })

  test("reviews a normal sentence", () => {
    expect(shouldSkipCheck("I wants to refactor this function")).toBe(false)
  })

  test("reviews a substantial CJK prompt by character count", () => {
    expect(shouldSkipCheck("我想重构这个函数但是不知道怎么下手")).toBe(false)
  })

  test("skips identifier-heavy text", () => {
    expect(shouldSkipCheck("getUserById(id) -> fetchData(url) -> parseResult(x)")).toBe(true)
  })
})

describe("review prompt", () => {
  test("names both languages and asks for JSON", () => {
    const prompt = buildReviewPrompt("I wants to go", { ...DEFAULT_SETTINGS, learning: "en", native: "zh-CN" })
    expect(prompt).toContain("English writing tutor")
    expect(prompt).toContain("zh-CN")
    expect(prompt).toContain('"mode": "check"')
    expect(prompt).toContain("I wants to go")
  })

  test("truncates very long prompts", () => {
    const prompt = buildReviewPrompt("x".repeat(5000), DEFAULT_SETTINGS)
    expect(prompt.length).toBeLessThan(3000)
  })
})

describe("review parsing", () => {
  test("parses a check result", () => {
    const result = parseReviewResult(
      JSON.stringify({
        mode: "check",
        items: [{ wrong: "I wants", right: "I want", reason: "主语是 I" }],
        rephrase: "I'd like to refactor this function.",
      }),
    )
    expect(result).toEqual({
      mode: "check",
      items: [{ wrong: "I wants", right: "I want", reason: "主语是 I" }],
      rephrase: "I'd like to refactor this function.",
    })
  })

  test("tolerates a fenced JSON answer", () => {
    const result = parseReviewResult(
      'Here you go:\n```json\n{"mode":"check","items":[],"rephrase":null}\n```',
    )
    expect(result).toEqual({ mode: "check", items: [] })
  })

  test("parses skip", () => {
    expect(parseReviewResult('{"mode":"skip"}')).toEqual({ mode: "skip" })
  })

  test("caps items at three and drops malformed entries", () => {
    const result = parseReviewResult(
      JSON.stringify({
        mode: "check",
        items: [
          { wrong: "a", right: "b", reason: "r" },
          { wrong: "c", right: "d", reason: "r" },
          { wrong: "e", right: "f", reason: "r" },
          { wrong: "g", right: "h", reason: "r" },
          { wrong: "", right: "x", reason: "r" },
        ],
      }),
    )
    expect(result?.mode).toBe("check")
    if (result?.mode === "check") expect(result.items).toHaveLength(3)
  })

  test("rejects unrelated JSON", () => {
    expect(parseReviewResult('{"answer":42}')).toBeUndefined()
    expect(parseReviewResult("not json")).toBeUndefined()
  })
})

describe("utilities", () => {
  test("extracts JSON from surrounding prose", () => {
    expect(extractJson<{ ok: boolean }>('prefix {"ok":true} suffix')).toEqual({ ok: true })
  })

  test("truncates on a word boundary-ish ellipsis", () => {
    expect(truncate("hello   world", 20)).toBe("hello world")
    expect(truncate("abcdefghij", 5)).toBe("abcd…")
  })
})
