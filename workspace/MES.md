# SMT MES checks

The bot may quote only the checks written in this file.
Add a block when a real line check is known. Leave "Checks" as "none yet" until then.

## Reply fields

- Line
- Station
- What failed
- Since when
- Who to call

## Glue line 17, final VI

- Reported in the group: final VI stage system not working again.
- Checks: none yet.
- Call: ME Team.

## CPU not working

- Reported in the group: CPU not working properly. Line and station were not confirmed on the same message.
- Checks: none yet.
- Call: ME Team. If it is a program or process issue, also call PE Team.

## Add a check

Copy this block, fill it, and save the file. Restart is not required for the next reply to see it.

```text
## <line and station>

- Symptom:
- Check 1:
- Check 2:
- Call:
```
