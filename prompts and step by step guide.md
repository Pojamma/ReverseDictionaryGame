Heck yeah, Big Bad Bob—here are **copy-paste prompts** you can give to any LLM to (1) generate puzzle content, (2) QA/clean it, (3) convert/merge formats, and (4) spit out code, store text, and translations. I also included **step-by-step instructions** so you can run this as a repeatable pipeline.

---

# How to use these prompts (quick guide)

1. Pick a task below → copy the prompt → fill the 🔷 placeholders.
2. Ask the LLM to **return output in a single fenced code block**.
3. **Generate in batches** (e.g., 50–100 puzzles) to keep it clean.
4. Run the **QA/Validator prompt** on the result.
5. Save to file and test in your app.
6. Rinse & repeat for more packs (Movies/TV, Holiday, Idioms, etc.).

---

# A) Master Puzzle Generator (JSON)

**Use this to create any pack: definitions, emoji, riddles—mixed or themed.**

**Prompt:**

```
You are a senior puzzle designer for a Reverse Dictionary word game.
TASK: Generate 🔷<COUNT> puzzles as JSON that follow this schema:

{
  "version": "1.0.0",
  "packs": [{
    "pack_id": "🔷<PACK_ID>",
    "name": "🔷<PACK_NAME>",
    "description": "🔷<PACK_DESCRIPTION>",
    "puzzles": [
      {
        "id": "🔷<PACK_PREFIX>-0001",
        "type": "definition|emoji|riddle",
        "clue": "string",
        "answer": "string (lowercase, no trailing spaces)",
        "alt_answers": ["list","of","synonyms or variants"],
        "category": "🔷<CATEGORY or THEME>",
        "difficulty": 1|2|3,
        "length": int(answer length),
        "hints": ["short","useful"],
        "tags": ["topic","mode"],
        "points": 10|12|14   // scale with difficulty: 10(easy) / 12(med) / 14(hard)
      }
    ]
  }]
}

CONSTRAINTS:
- Distribution by type: 🔷<TYPE_DISTRIBUTION> (e.g., 40% definition, 40% emoji, 20% riddle).
- Difficulty mix: 🔷<DIFFICULTY_DISTRIBUTION> (e.g., 50% d1, 35% d2, 15% d3).
- All answers must be UNIQUE (case-insensitive) within the pack.
- Keep emoji puzzles to ≤ 3 emojis (4 max if truly needed).
- Hints must be short, non-spoilery, and helpful.
- Avoid offensive or NSFW content.
- Accept common variants via alt_answers (spelling, hyphenation, plural/singular).
- For multi-word answers, use spaces (e.g., "global warming"). No punctuation at the end.
- Categories and tags must be consistent with the theme: 🔷<THEME_NOTES>.
- If a clue could match multiple answers, disambiguate the clue.

OUTPUT:
- Return JSON ONLY in one code-fenced block (no commentary).
- IDs should be sequential (🔷<PACK_PREFIX>-0001, -0002, ...).
```

---

# B) Emoji-Only Generator (premium packs love these)

**Prompt:**

```
Create 🔷<COUNT> emoji-only puzzles as JSON for pack 🔷<PACK_ID> ("🔷<PACK_NAME>").
Theme: 🔷<THEME> (e.g., Movies & TV, Idioms, Holiday Foods).

Rules:
- clue = 2–3 emojis (max 4 if needed).
- Each emoji sequence must strongly imply a single real answer.
- Include 2 short hints that describe the idea without revealing the exact answer.
- difficulty: mostly 1–2, a few 3 for clever combos.
- alt_answers: include natural variants (e.g., "spider-man" vs "spiderman").

Use the schema from the Master Puzzle Generator and output JSON only.
```

---

# C) Riddle-Only Generator

**Prompt:**

```
Generate 🔷<COUNT> short riddles as JSON for pack 🔷<PACK_ID> ("🔷<PACK_NAME>").
Audience: 12+ casual mobile players.
Rules:
- Riddles must be solvable in <30s by a typical player.
- Avoid reused classics unless you paraphrase them; target fresh wording.
- One unambiguous answer per riddle; add alt_answers for common synonyms.
- Provide 2 concise hints.

Use the schema from the Master Puzzle Generator and output JSON only.
```

---

# D) Themed Pack Generator (e.g., Idioms & Sayings)

**Prompt:**

```
Create 🔷<COUNT> puzzles for the premium pack 🔷<PACK_ID> ("🔷<PACK_NAME>") with theme "🔷Idioms & Sayings".
Types: 60% emoji (idioms via emoji), 25% definition (meaning of idiom), 15% riddle (clues pointing to the idiom).
Examples of answers: "break the ice", "piece of cake", "spill the beans", etc.
Each puzzle:
- For emoji type, prefer 2–3 emojis that evoke the idiom metaphorically (not literal translations).
- alt_answers should include common punctuation/space variants.
- Hints should nudge the metaphor (“social opener”, “very easy task”, “reveal a secret”).
Use the standard JSON schema; output JSON only.
```

---

# E) QA / Validator / Deduplicator (run AFTER generation)

**Prompt:**

```
You are a strict content QA bot. I will paste a JSON pack following this schema (packs[0].puzzles[*]).
TASKS:
1) Validate JSON structure and required fields.
2) Enforce rules:
   - Unique 'answer' across puzzles (case-insensitive).
   - difficulty in {1,2,3}; points aligned to difficulty (10/12/14).
   - hints are short and helpful; alt_answers aren’t duplicates of answer.
   - emoji puzzles have ≤3 emojis (4 max).
   - riddle clues have a single, unambiguous solution.
3) Identify issues:
   - duplicates, ambiguous clues, unsafe or NSFW content, factual errors.
   - overly obscure answers for casual audience.
4) FIXES:
   - For minor issues, return a corrected JSON.
   - For ambiguous/duplicate items that can’t be salvaged, remove them and list their IDs in a "removed" array.

OUTPUT FORMAT:
{
  "report": {
    "errors": [...],
    "warnings": [...],
    "removed_ids": [...]
  },
  "fixed": { /* corrected JSON pack, same schema */ }
}

Return one fenced code block containing valid JSON only.
```

---

# F) JSON → SQLite Converter (LLM rewrite)

**Prompt:**

```
Convert this JSON pack into SQL INSERT statements for two tables:

packs(pack_id, name, description)
puzzles(id, pack_id, type, clue, answer, alt_answers, category, difficulty, length, hints, tags, points, is_active)

Notes:
- alt_answers, hints, tags should be JSON strings (escaped) suitable for TEXT columns.
- Use INSERT ... ON CONFLICT DO NOTHING where applicable (if supported).
- Ensure pack row is inserted first.
- Return a single fenced code block with SQL only (no commentary).
```

---

# G) Merger / Normalizer (combine multiple packs safely)

**Prompt:**

```
Merge these N JSON packs into ONE consistent pack list:
- Keep original pack_id/name/description.
- For each pack, ensure puzzles have unique IDs and unique 'answer's within that pack.
- If an answer collides across packs, DO NOT change existing packs; only rename the new ID (not the answer) and leave a "note" in a separate 'collisions' section of the final report.
- Normalize fields:
  - lowercase 'answer'
  - compute 'length' from answer
  - points = 10/12/14 by difficulty
Return one code-fenced JSON with:
{
  "report": { "collisions": [...], "summary": { "total_packs": X, "total_puzzles": Y } },
  "data": { "version": "1.0.0", "packs": [...] }
}
No prose.
```

---

# H) Unity Loader + Systems (code generator)

**Prompt:**

```
Write Unity C# scripts for an Android word game:

FILES:
1) PuzzleModels.cs – serializable classes for Puzzle, Pack, Root.
2) PuzzleRepository.cs – loads packs from StreamingAssets (JSON), validates, indexes by id, random sampler by type/difficulty, and daily-challenge selector seeded by local date.
3) GameLoop.cs – shows clue, accepts text input, checks answer (case-insensitive, trims), awards coins, reveals letter (cost coins), skip (cost coins), and supports rewarded-ad callbacks (placeholder methods).
4) Economy.cs – simple coin balance (PlayerPrefs), cost constants, grant on correct answers, streak bonus logic.
5) Settings.cs – difficulty preferences and accessibility flags (large font).
6) AdShim.cs – AdMob placeholders: ShowRewarded(string reason), ShowInterstitialEveryNLevels(int N). Implement events but leave TODOs for real ad unit IDs.
7) IAPShim.cs – Google Play Billing placeholders: PurchaseRemoveAds(), PurchaseHintPack(int amount), PurchasePack(string packId). Include success/failure callbacks.

REQUIREMENTS:
- Clean, compilable code with namespaces.
- No external assets; comment where AdMob/IAP SDK calls go.
- Minimal UI stubs (public fields for TextMeshProUGUI, Buttons).
Return all files concatenated in ONE fenced code block, with clear // --- FILE: headers.
```

---

# I) Flutter Loader + Systems (code generator)

**Prompt:**

```
Write Flutter/Dart code for an Android word game:

FILES:
- models.dart (Puzzle, Pack, Root with fromJson)
- repo.dart (load asset JSON, cache packs, random sampler, daily challenge by date seed)
- game_logic.dart (check answers, hint/skip economy, streaks)
- ad_shim.dart (stubs for google_mobile_ads rewarded/interstitial)
- iap_shim.dart (stubs for in_app_purchase purchases)

Constraints: Pure Dart (no platform channels yet), functions that I can later wire to UI. Return all files in a single fenced code block.
```

---

# J) Store Listing & Screenshots Copy

**Prompt:**

```
Create Google Play store text for "WordQuest: Reverse Dictionary":
- 30-char Title options (x5)
- 80-char Short description options (x5)
- 400–700 char Full description (x2 variants)
- 7 bullet points of features
- 10 SEO keywords/phrases

Tone: fun, clever, family-friendly. Emphasize daily challenge, hints, and premium packs. Output as clean Markdown only.
```

---

# K) Localization (optional)

**Prompt:**

```
Localize this pack to 🔷<LANGUAGE> for casual players:
- Translate 'clue' and 'hints' only.
- Keep 'answer' and 'alt_answers' in the target language; if the concept lacks a natural translation, replace with a culturally equivalent, short, common word/phrase and note the substitution in a "notes" array alongside the puzzle ID.
- Preserve emoji as-is.
Return the modified JSON with an added "lang": "🔷<LANGUAGE_CODE>" at root.
```

---

## Step-by-step workflow (repeatable)

1. **Plan the pack**

   * Theme, count, type split, difficulty mix.

2. **Generate content**

   * Use **A or B/C/D** with your settings (50–100 per batch).

3. **Validate & fix**

   * Run **E (QA/Validator)** on the JSON. Save the fixed result.

4. **Merge**

   * If combining multiple outputs, run **G (Merger/Normalizer)**.

5. **Convert (optional)**

   * If you want SQLite inserts, run **F**.

6. **Wire into app**

   * Use **H (Unity)** or **I (Flutter)** to produce scaffolding.
   * Drop JSON into assets/StreamingAssets and test a small flow.

7. **Monetization**

   * Fill AdMob IDs in `AdShim`.
   * Set “every 5–7 puzzles” interstitial.
   * Add IAP products in Play Console, then wire in `IAPShim`.

8. **Store listing**

   * Use **J** for text; make 6–8 screenshots (mock UI is fine to start).

9. **Localization (optional)**

   * Use **K** to create one additional language (e.g., Spanish) and ship as a differentiator.

10. **Ship**

* Closed test → open testing → production.
* Track retention & ad views; adjust difficulty and hints.

---

If you want, tell me your **exact theme and target counts** for the next premium pack and I’ll pre-fill the Master Generator prompt with tuned distributions so you can just paste and go.
