# Startup Output and instance counts, 2026-11-14

Studio `Development-Juragan-Desa`, Play Solo, ~15-25 s after start. Window size NOT emulated to a phone;
the MCP cannot set the device emulator, so this is a desktop-window reading.

## Output (see `output.log`)
Server and client held only the external BUG-003 warning plus info lines. No errors. Covers startup only.

## Instance counts
| Scope | Value |
|---|---|
| Client DataModel descendants | 7897 |
| Client workspace | 1241 |
| Client PlayerGui | 947 |
| Client ReplicatedStorage | 84 |
| Server DataModel descendants | 4002 |
| Server workspace | 1231 |
| `Stats.InstanceCount` client / server | 58334 / 54379 (engine-wide, includes internal instances) |
| Client primitives | 332 |
| Client memory | 2377 MB (Studio process, not a device number) |
| Heartbeat time client / server | 0.50 ms / 0.02 ms |

## Frame rate: UNVERIFIED
RenderStepped averaged 15.0 fps over 8 s. That is not a usable number: Studio throttles when it is not
the focused window and the process holds ~2.4 GB. Real fps needs a focused window or a device.

## Observation (not a bug yet)
PlayerGui holds 947 instances at idle. Worth a track D look before the mid-range Android target.
