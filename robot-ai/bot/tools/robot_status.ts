import { defineTool } from "@cursor/bdk/tools";
import { z } from "zod/v3";

export default defineTool({
  description: "Report this robot's name, readiness, and current mode.",
  effect: "read",
  inputSchema: z.object({}),
  execute() {
    return { name: "SMES Robot", ready: true, mode: "assist" };
  },
});
