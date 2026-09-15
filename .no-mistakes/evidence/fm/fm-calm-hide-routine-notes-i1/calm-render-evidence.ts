export default function (pi: any) {
  pi.on("session_start", async () => {
    pi.sendMessage({
      customType: "fm-branch-merge",
      content: "⛵ routine-worker: healthy, no action needed",
      display: true,
    });
    pi.sendMessage({
      customType: "fm-branch-merge",
      content: "⛵ Supervision branch paused after repeated provider errors; main will handle wakes while it cools down.",
      display: true,
    });
    pi.sendMessage({
      customType: "fm-branch-merge",
      content: "⚓ legacy-task: captain review required",
      display: true,
    });
    pi.sendMessage({
      customType: "fm-branch-health",
      content: "⛵ Supervision branch recovered after a successful cooldown probe.",
      display: true,
    });
    pi.appendEntry("fm-branch-visible-outcome", {
      version: 1,
      seq: 42,
      task: "current-task",
      verdict: "captain",
      summary: "PR checks green, ready for captain review",
      silent: false,
    });
  });
}
