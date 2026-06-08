-- WW2 Germany Air Support System
-- 空中支援系统核心逻辑
-- ME323 运输 + 斯图卡轰炸 + Me262扫射

local AirSupport = {}
local activeMissions = {}
local cooldowns = {
  stuka = 0,
  me262 = 0,
  me323_military = 0
}

-- ============ 常量定义 ============
local CONFIG = {
  STUKA_COOLDOWN = 90,
  ME262_COOLDOWN = 60,
  ME323_COOLDOWN = 120,
  STUKA_DAMAGE = 85,
  STUKA_RADIUS = 3,
  ME262_DAMAGE = 35,
  ME262_RADIUS = 8,
  STUKA_SPEED = 3.5,
  ME262_SPEED = 6.0,
  MAP_EDGE_OFFSET = 50
}

-- ============ 任务ID生成 ============
local missionCounter = 0
local function GenerateMissionID()
  missionCounter = missionCounter + 1
  return "mission_" .. missionCounter
end

-- ============ 冷却管理 ============
function AirSupport.UpdateCooldowns()
  if cooldowns.stuka > 0 then
    cooldowns.stuka = cooldowns.stuka - 1
  end
  if cooldowns.me262 > 0 then
    cooldowns.me262 = cooldowns.me262 - 1
  end
  if cooldowns.me323_military > 0 then
    cooldowns.me323_military = cooldowns.me323_military - 1
  end
end

function AirSupport.GetCooldown(aircraftType)
  if aircraftType == "stuka" then
    return cooldowns.stuka
  elseif aircraftType == "me262" then
    return cooldowns.me262
  elseif aircraftType == "me323_military" then
    return cooldowns.me323_military
  end
  return 0
end

function AirSupport.IsAvailable(aircraftType)
  return AirSupport.GetCooldown(aircraftType) <= 0
end

-- ============ 斯图卡轰炸 ============
function AirSupport.CallStuka(targetX, targetY)
  if not AirSupport.IsAvailable("stuka") then
    return false, "斯图卡正在冷却中...剩余 " .. cooldowns.stuka .. " 秒"
  end
  
  local missionID = GenerateMissionID()
  local startX = -CONFIG.MAP_EDGE_OFFSET
  local startY = targetY
  
  -- 创建任务数据
  local mission = {
    id = missionID,
    type = "stuka",
    targetX = targetX,
    targetY = targetY,
    startX = startX,
    startY = startY,
    state = "incoming",  -- incoming -> bombing -> departing -> complete
    progress = 0,
    totalFrames = 180  -- 3秒完成
  }
  
  activeMissions[missionID] = mission
  cooldowns.stuka = CONFIG.STUKA_COOLDOWN
  
  return true, "斯图卡已出动！目标位置：(" .. targetX .. ", " .. targetY .. ")"
end

-- ============ Me262扫射 ============
function AirSupport.CallMe262(startX, startY, endX, endY)
  if not AirSupport.IsAvailable("me262") then
    return false, "Me262正在冷却中...剩余 " .. cooldowns.me262 .. " 秒"
  end
  
  local missionID = GenerateMissionID()
  
  -- 创建任务数据
  local mission = {
    id = missionID,
    type = "me262",
    startX = startX,
    startY = startY,
    endX = endX,
    endY = endY,
    state = "incoming",  -- incoming -> strafing -> departing -> complete
    progress = 0,
    totalFrames = 240  -- 4秒完成
  }
  
  activeMissions[missionID] = mission
  cooldowns.me262 = CONFIG.ME262_COOLDOWN
  
  return true, "Me262已出动！扫射路线：(" .. startX .. ", " .. startY .. ") → (" .. endX .. ", " .. endY .. ")"
end

-- ============ ME323兵力运输 ============
function AirSupport.CallME323Military(targetHelipadX, targetHelipadY)
  if not AirSupport.IsAvailable("me323_military") then
    return false, "ME323正在冷却中...剩余 " .. cooldowns.me323_military .. " 秒"
  end
  
  cooldowns.me323_military = CONFIG.ME323_COOLDOWN
  return true, "ME323兵力运输机已调度！120名精英士兵即将空投到指定位置。"
end

-- ============ 任务执行更新 ============
function AirSupport.UpdateMissions()
  local completedMissions = {}
  
  for missionID, mission in pairs(activeMissions) do
    mission.progress = mission.progress + 1
    local progress_ratio = mission.progress / mission.totalFrames
    
    if mission.type == "stuka" then
      AirSupport.UpdateStukaMission(mission, progress_ratio)
    elseif mission.type == "me262" then
      AirSupport.UpdateMe262Mission(mission, progress_ratio)
    end
    
    -- 任务完成
    if mission.progress >= mission.totalFrames then
      table.insert(completedMissions, missionID)
    end
  end
  
  -- 移除已完成的任务
  for _, missionID in ipairs(completedMissions) do
    activeMissions[missionID] = nil
  end
end

-- 斯图卡任务步骤
function AirSupport.UpdateStukaMission(mission, progress_ratio)
  if progress_ratio < 0.33 then
    -- 阶段1：接近
    mission.state = "incoming"
    mission.currentX = mission.startX + (mission.targetX - mission.startX) * (progress_ratio / 0.33)
    mission.currentY = mission.startY
    
  elseif progress_ratio < 0.66 then
    -- 阶段2：轰炸
    mission.state = "bombing"
    mission.currentX = mission.targetX
    mission.currentY = mission.targetY
    
    -- 第一次到达轰炸点时执行伤害
    if progress_ratio >= 0.33 and progress_ratio < 0.4 then
      if not mission.bomb_triggered then
        AirSupport.ExecuteStukaBomb(mission.targetX, mission.targetY)
        mission.bomb_triggered = true
      end
    end
    
  else
    -- 阶段3：离开
    mission.state = "departing"
    local departProgress = (progress_ratio - 0.66) / 0.34
    mission.currentX = mission.targetX + (500 - mission.targetX) * departProgress
    mission.currentY = mission.targetY
  end
end

-- 执行斯图卡轰炸伤害
function AirSupport.ExecuteStukaBomb(bombX, bombY)
  -- 游戏引擎集成点
  -- CreateExplosion(bombX, bombY, CONFIG.STUKA_RADIUS, CONFIG.STUKA_DAMAGE, true)
  -- PlaySound("sounds/stuka_bomb", bombX, bombY)
  -- DamageObjectsInRadius(bombX, bombY, CONFIG.STUKA_RADIUS * 2, CONFIG.STUKA_DAMAGE, "fire")
end

-- Me262任务步骤
function AirSupport.UpdateMe262Mission(mission, progress_ratio)
  if progress_ratio < 0.25 then
    -- 阶段1：接近
    mission.state = "incoming"
    mission.currentX = mission.startX + (mission.endX - mission.startX) * (progress_ratio / 0.25)
    mission.currentY = mission.startY
    
  elseif progress_ratio < 0.75 then
    -- 阶段2：扫射
    mission.state = "strafing"
    mission.currentX = mission.startX + (mission.endX - mission.startX) * ((progress_ratio - 0.25) / 0.5)
    mission.currentY = mission.startY
    
    -- 不断造成伤害
    AirSupport.ExecuteMe262Strafe(mission)
    
  else
    -- 阶段3：离开
    mission.state = "departing"
    local departProgress = (progress_ratio - 0.75) / 0.25
    mission.currentX = mission.endX + (500 - mission.endX) * departProgress
    mission.currentY = mission.endY
  end
end

-- 执行Me262扫射伤害
function AirSupport.ExecuteMe262Strafe(mission)
  -- 游戏引擎集成点
  -- CreateStrafeLine(mission.startX, mission.startY, mission.endX, mission.endY, CONFIG.ME262_DAMAGE)
  -- PlaySound("sounds/me262_mg", mission.currentX, mission.currentY)
  -- SuppressObjectsInLine(mission.startX, mission.startY, mission.endX, mission.endY, CONFIG.ME262_DAMAGE)
end

-- ============ 对外接口 ============
function AirSupport.GetStatus()
  return {
    stuka_available = AirSupport.IsAvailable("stuka"),
    stuka_cooldown = cooldowns.stuka,
    me262_available = AirSupport.IsAvailable("me262"),
    me262_cooldown = cooldowns.me262,
    me323_available = AirSupport.IsAvailable("me323_military"),
    me323_cooldown = cooldowns.me323_military,
    active_missions = #activeMissions
  }
end

function AirSupport.GetActiveMissions()
  local missionList = {}
  for missionID, mission in pairs(activeMissions) do
    table.insert(missionList, {
      id = mission.id,
      type = mission.type,
      state = mission.state,
      progress = mission.progress,
      totalFrames = mission.totalFrames,
      progressPercent = (mission.progress / mission.totalFrames) * 100
    })
  end
  return missionList
end

-- ============ 主更新函数 ============
function AirSupport.Update(deltaTime)
  AirSupport.UpdateCooldowns()
  AirSupport.UpdateMissions()
end

return AirSupport
