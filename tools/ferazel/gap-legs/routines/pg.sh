#!/bin/zsh
cd /Users/andiyar/Developer/Ambrosia-Classics/.claude/worktrees/gap-ledger/Ferazel
grep -rnE "$1" Core/Sources Shared App Windows/Sources 2>/dev/null | sed 's/^/  /' | cut -c1-${2:-220} | head -${3:-8}
