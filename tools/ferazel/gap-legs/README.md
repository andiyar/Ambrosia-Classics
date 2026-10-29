# Gap-ledger classification aids (2026-10-30)

The helper scripts the two analysis legs wrote while classifying, kept so the work can be redone. They are aids, not a
pipeline: some read intermediate pickles/TSVs from the leg's scratch folder (paths inside the scripts). The committed
results are `docs/ferazel/gap-ledger/resources-classified.tsv` and `routines-classified.tsv`;
`routines/overrides.py` holds every hand decision of the routine table.
The re-runnable inventories are one level up: `gap-markers.py`, `gap-routines.py`, `gap-placements.py`,
`gap-trace.sh` + `gap-resources.py`.
