import { defineEval } from "@cursor/bdk/evals";

export default defineEval({
  tags: ["smoke"],
  async test(t) {
    await t.send("What is your robot status?");
    t.succeeded();
    t.calledTool("robot_status");
  },
});
