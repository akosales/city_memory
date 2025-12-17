-- ================================================
-- City Memory System - Shared Utilities
-- Helper-Funktionen für Client & Server
-- ================================================

-- ================================================
-- Job Helper Functions
-- ================================================

function IsJobInList(jobName, jobList)
    if not jobName or not jobList then return false end
    for _, job in ipairs(jobList) do
        if job == jobName then
            return true
        end
    end
    return false
end

function IsPoliceJob(jobName)
    return IsJobInList(jobName, Config.Jobs.police)
end

function IsEMSJob(jobName)
    return IsJobInList(jobName, Config.Jobs.ems)
end

function IsAdminJob(jobName)
    return IsJobInList(jobName, Config.Jobs.admin)
end

function IsDispatcherJob(jobName)
    return IsPoliceJob(jobName) or IsEMSJob(jobName)
end

function CanSeeCategory(jobName, category)
    local cat = Config.Categories[category]
    if not cat then return true end
    
    if IsPoliceJob(jobName) and cat.police then return true end
    if IsEMSJob(jobName) and cat.ems then return true end
    
    return false
end

-- ================================================
-- Priority Helpers
-- ================================================

function GetPriorityOrder(priority)
    local order = { high = 1, medium = 2, low = 3 }
    return order[priority] or 99
end

function GetPriorityLabel(priority)
    local labels = {
        high = '🔴 HOCH',
        medium = '🟡 MITTEL',
        low = '🟢 NIEDRIG'
    }
    return labels[priority] or priority
end

function GetPriorityColor(priority)
    local colors = {
        high = Config.UI.priorityHigh or '#f44336',
        medium = Config.UI.priorityMedium or '#ff9800',
        low = Config.UI.priorityLow or '#4caf50'
    }
    return colors[priority] or '#888888'
end

-- ================================================
-- Status Helpers
-- ================================================

function GetStatusLabel(status)
    local labels = {
        open = 'Offen',
        accepted = 'Angenommen',
        enroute = 'Unterwegs',
        onscene = 'Vor Ort',
        completed = 'Abgeschlossen',
        expired = 'Abgelaufen'
    }
    return labels[status] or status
end

-- ================================================
-- Risk Level Helpers
-- ================================================

function GetRiskLabel(risk)
    local labels = {
        high = '🔴 Hohes Risiko',
        medium = '🟡 Mittleres Risiko',
        low = '🟢 Geringes Risiko',
        unknown = '⚪ Unbekannt',
        clean = '🟢 Unauffällig'
    }
    return labels[risk] or risk
end

function GetRiskColor(risk)
    local colors = {
        high = '#f44336',
        medium = '#ff9800',
        low = '#4caf50',
        unknown = '#888888',
        clean = '#4caf50'
    }
    return colors[risk] or '#888888'
end

-- ================================================
-- Time Helpers
-- ================================================

function FormatTimeAgo(timestamp)
    local now = os.time()
    local diff = now - timestamp
    
    if diff < 60 then
        return 'vor ' .. diff .. ' Sek'
    elseif diff < 3600 then
        return 'vor ' .. math.floor(diff / 60) .. ' Min'
    elseif diff < 86400 then
        return 'vor ' .. math.floor(diff / 3600) .. ' Std'
    else
        return 'vor ' .. math.floor(diff / 86400) .. ' Tagen'
    end
end

function FormatDateTime(timestamp)
    return os.date('%d.%m.%Y %H:%M', timestamp)
end
