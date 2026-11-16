# Rebuild batching bench

This measures `RecordingStudioSitemaps.rebuild!` on a seeded dummy app. It does not open a pull request, and it does not submit a sitemap to a search engine.

The seed builds about 3,700 published indexable pages across 850 workspace roots, plus drafts, scheduled pages, expired pages, noindex pages, trashed pages, and published pages whose slug starts with `bench-private`. States come from `Publishables::Update` and `RecordingStudioTrashable.void_recording!`. Publishable has no private scope, so the private slug is only a label.

During the seed the script turns off the publish hook. That hook calls `rebuild!` after every publishable write. Left on, the seed rebuilds the whole sitemap once per page.

Run it from `test/dummy`. Use a database name that is not `app_development`.

```bash
DB_NAME=sitemap_bench SEED=1 bundle exec rails runner /workspace/bench/rebuild_batching.rb
DB_NAME=sitemap_bench MEASURE=1 MODE=stock RUNS=5 bundle exec rails runner /workspace/bench/rebuild_batching.rb
DB_NAME=sitemap_bench MEASURE=1 MODE=preload RUNS=5 bundle exec rails runner /workspace/bench/rebuild_batching.rb
DB_NAME=sitemap_bench MEASURE=1 MODE=join RUNS=5 bundle exec rails runner /workspace/bench/rebuild_batching.rb
DB_NAME=sitemap_bench EXPOSURE=1 bundle exec rails runner /workspace/bench/rebuild_batching.rb
```

`MODE=gem` measures the code on disk. `MODE=stock` forces one URL lookup per row. `MODE=preload` loads parent, child, and publishable rows once per batch and calls `RecordingStudioPublishable::Routing.url_for`. `MODE=join` reads those fields from the indexable join. `PROFILE=wall` writes a stackprof dump. `MEMORY=1` writes a memory_profiler report. `CACHE=0` turns the query cache off. `NOISY=1` leaves the development logger on.

Results land in `/opt/cursor/artifacts/bench/`.

v0.9.0 is the same script against a worktree checked out at tag `v0.9.0`, with `DB_NAME=sitemap_bench_090`. Core 6 and core 7 do not share a schema, so the two databases are separate. The seed counts match.

## What the first run measured

Five runs, one warmup thrown away, query cache on, logger silenced, 4 cores. The claim written before the runs was that the after median had to fall below the before minimum.

| version | path | wall median | range | uncached queries | SQL ms | allocations | peak RSS |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 0.9.0 | stock | 17,145 ms | 16,738 to 17,329 | 15,278 | 4,795 | 9,994,500 | 182 MB |
| 0.9.0 | preload | 424 ms | 412 to 439 | 41 | 130 | 599,301 | 155 MB |
| 0.11.1 | stock | 18,114 ms | 18,001 to 18,909 | 15,301 | 5,086 | 10,776,084 | 183 MB |
| 0.11.1 | code on disk | 596 ms | 530 to 633 | 41 | 142 | 871,047 | 155 MB |

A joined select was also measured (349 ms on 0.9.0, 472 ms on 0.11.1) and left out of the gem. A second kept parent recording can make that select emit two rows for one page. Preload uses the same latest parent and lowest-id child as `indexable_url`.

XML was byte-identical within each version. Main writes 3,809 URLs and 587,567 bytes. v0.9.0 writes 3,819 URLs and 584,888 bytes, because v0.9.0 has no host check and keeps the ten `press.example` canonicals.

Draft, scheduled, expired, noindex, and trashed slugs were absent. The 120 `bench-private` slugs were present. Publishable has no private scope, so those pages are indexable. `Page.unpublished` stayed empty, because `Update` clears `unpublish_at` when the status is draft. The excluded window is a published row whose publish and unpublish times are both in the past.

`MODE=gem` is the code in `Sources::Publishable`. `MODE=stock` forces the old per-row lookups on top of that file, so the comparison can be repeated. The v0.9.0 preload lives only in this script (`install_v090_preload!`). This branch does not bump `VERSION`.
