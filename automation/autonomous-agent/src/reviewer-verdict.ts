import type { Verdict } from "./types.js";

export function validateReviewerVerdict(value: unknown): Verdict {
  if (!value || typeof value !== "object") throw new Error("Reviewer returned malformed output");
  const item = value as Verdict;
  if (item.schemaVersion !== 1 || !["approved", "request_changes"].includes(item.verdict) || typeof item.summary !== "string" || !Array.isArray(item.findings)) throw new Error("Reviewer returned malformed verdict");
  for (const finding of item.findings) if (!finding || !["blocking", "non_blocking"].includes(finding.severity) || typeof finding.message !== "string") throw new Error("Reviewer returned malformed finding");
  if (item.verdict === "approved" && item.findings.some((finding) => finding.severity === "blocking")) throw new Error("Approved verdict contains blocking findings");
  return item;
}
