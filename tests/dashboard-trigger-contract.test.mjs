import assert from "node:assert/strict";
import { readFile, stat } from "node:fs/promises";
import { dirname, join } from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";

const repositoryRoot = join(dirname(fileURLToPath(import.meta.url)), "..");
const storySkillRoot = join(repositoryRoot, "skills", "story");

async function read(relativePath) {
  return readFile(join(repositoryRoot, relativePath), "utf8");
}

test("story skill exposes the platform-specific dashboard triggers", async () => {
  const skill = await read("skills/story/SKILL.md");

  assert.match(skill, /^name: story$/m);
  assert.match(skill, /\/story dashboard/);
  assert.match(skill, /\$story dashboard/);
  assert.match(
    skill,
    /\| 工作台 \| dashboard、工作台、看拆文库、浏览项目文件、打开项目面板 \| 见下方「Dashboard 工作台」 \|/,
  );
  assert.match(
    skill,
    /node "<story-skill-dir>\/scripts\/dashboard-server\.mjs" --root "<workspace>" --open/,
  );
  assert.match(skill, /默认只监听 `127\.0\.0\.1`/);
  assert.match(skill, /不要主动增加 `--allow-network`/);
});

test("Codex plugin exposes the canonical story skill bundle", async () => {
  const plugin = JSON.parse(await read(".codex-plugin/plugin.json"));

  assert.equal(plugin.name, "oh-story-codex");
  assert.equal(plugin.skills, "./skills/");

  for (const relativePath of [
    "SKILL.md",
    "scripts/dashboard-server.mjs",
    "assets/index.html",
    "assets/styles.css",
    "assets/app.js",
  ]) {
    const bundled = await stat(join(storySkillRoot, relativePath));
    assert.ok(bundled.isFile(), `${relativePath} must ship inside the canonical story skill`);
  }
});
