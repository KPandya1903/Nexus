"""DEPRECATED — moved to api.shared.usage.

This shim preserves back-compat for any code path that still imports from the
old location. New imports should use:

    from api.shared.usage import UsageRecord, log_usage, reset_run, write_run_summary

The shim re-exports the canonical objects from the shared module so behavior
is unchanged. Will be removed once all consumers migrate.

(GitHub MCP cannot delete files in this workflow, so the shim is the cleanest
no-breakage migration path. Manually `git rm` this file in a worktree once
all imports have moved off it.)
"""

from api.shared.usage import (  # noqa: F401
    UsageRecord,
    log_usage,
    reset_run,
    write_run_summary,
)
