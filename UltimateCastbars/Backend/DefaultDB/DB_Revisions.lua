
local ADDON_NAME, UCB = ...

UCB.Migration = UCB.Migration or {}

local Migrations = UCB.Migration

function UCB:RegisterMigrations()
    -- Only register once
    if UCB._migrationsRegistered then return end
    UCB._migrationsRegistered = true

    -- Revision 1: move top-level style -> styleCastType.general
    Migrations.RegisterRevision(1,
        function(p)
            -- move only if old exists and new missing
            Migrations.MovePath(p.player, {"style"}, {"styleCastType", "general"}, { onlyIfDestNil = false })
            Migrations.MovePath(p.target, {"style"}, {"styleCastType", "general"}, { onlyIfDestNil = false })
            Migrations.MovePath(p.focus, {"style"}, {"styleCastType", "general"}, { onlyIfDestNil = false })
        end
    )
end