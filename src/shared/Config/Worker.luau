-- Buruh tani (v2 PLAN §3.4). A hired NPC harvests ready crops straight into the gudang
-- while you are online, and takes a wage per item. He stops when the gudang is full or the
-- cash runs out.
--
-- Values are starting points for the balance sheet.

local Worker = {}

Worker.hireCost = 150 -- paid up front for one shift
Worker.hireSeconds = 300 -- five minutes
Worker.wagePerItem = 2 -- deducted per harvested item
Worker.intervalSeconds = 20 -- between passes
Worker.maxItemsPerPass = 5

return Worker
