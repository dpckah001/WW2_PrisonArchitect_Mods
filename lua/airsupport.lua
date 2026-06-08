-- WW2 Germany Air Support System
-- 空中支援系統核心邏輯
-- ME323 運輸 + 斯圖卡轟炸 + Me262掃射

local AirSupport = {}
local activeMissions = {}
local cooldowns = {
  stuka = 0,
  me262 = 0,
  me323_military = 0
}

-- ============ 常量定義 ============
-- 根據實際音效時長調整
local CONFIG = {
  -- 冷卻時間（秒）- 根據任務總時長設定
  STUKA_COOLDOWN = 90,
  ME262_COOLDOWN = 60,
  ME323_COOLDOWN = 120,
  
  -- 傷害參數
  STUKA_DAMAGE = 85,
  STUKA_RADIUS = 3,
  ME262_DAMAGE = 35,
  ME262_RADIUS = 8,
  
  -- 飛行速度
  STUKA_SPEED = 3.5,
  ME262_SPEED = 6.0,
  
  -- 地圖邊緣偏移
  MAP_EDGE_OFFSET = 50,
  
  -- 音效時長（秒）- 實際測量值
  STUKA_DIVE_DURATION = 30,      -- stuka_dive.wav 實際 30 秒
  STUKA_BOMB_DURATION = 2,       -- stuka_bomb.wav 實際 2 秒
  ME323_ENGINE_DURATION = 2,     -- me323_engine.wav 實際 2 秒
  ME262_JET_DURATION = 1,        -- me262_jet.wav 實際 1 秒
  ME262_MG_DURATION = 3,         -- me262_mg.wav 實際 3 秒
}

-- ============ 任務ID生成 ============
local missionCounter = 0
local function GenerateMissionID()
  missionCounter = missionCounter + 1
  return "mission_" .. missionCounter
end

-- ============ 冷卻管理 ============
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

-- ============ 斯圖卡轟炸 ============
-- 音效：stuka_dive (30秒) + stuka_bomb (2秒)
-- 總時長：32秒
function AirSupport.CallStuka(targetX, targetY)
  if not AirSupport.IsAvailable("stuka") then
    return false, "斯圖卡正在冷卻中...剩餘 " .. cooldowns.stuka .. " 秒"
  end
  
  local missionID = GenerateMissionID()
  local startX = -CONFIG.MAP_EDGE_OFFSET
  local startY = targetY
  
  -- 創建任務數據
  -- 總時長 32 秒 = 30秒俯衝 + 2秒爆炸
  local mission = {
    id = missionID,
    type = "stuka",
    targetX = targetX,
    targetY = targetY,
    startX = startX,
    startY = startY,
    state = "incoming",  -- incoming -> bombing -> departing -> complete
    progress = 0,
    totalFrames = 1920,  -- 32秒 * 60幀/秒 = 1920幀
    soundStarted = false,
    bombStarted = false
  }
  
  activeMissions[missionID] = mission
  cooldowns.stuka = CONFIG.STUKA_COOLDOWN
  
  return true, "斯圖卡已出動！目標位置：(" .. targetX .. ", " .. targetY .. ")"
end

-- ============ Me262掃射 ============
-- 音效：me262_jet (1秒) + me262_mg (3秒)
-- 總時長：4秒
function AirSupport.CallMe262(startX, startY, endX, endY)
  if not AirSupport.IsAvailable("me262") then
    return false, "Me262正在冷卻中...剩餘 " .. cooldowns.me262 .. " 秒"
  end
  
  local missionID = GenerateMissionID()
  
  -- 創建任務數據
  -- 總時長 4 秒 = 1秒接近 + 3秒掃射
  local mission = {
    id = missionID,
    type = "me262",
    startX = startX,
    startY = startY,
    endX = endX,
    endY = endY,
    state = "incoming",  -- incoming -> strafing -> departing -> complete
    progress = 0,
    totalFrames = 240,  -- 4秒 * 60幀/秒 = 240幀
    soundStarted = false
  }
  
  activeMissions[missionID] = mission
  cooldowns.me262 = CONFIG.ME262_COOLDOWN
  
  return true, "Me262已出動！掃射路線：(" .. startX .. ", " .. startY .. ") → (" .. endX .. ", " .. endY .. ")"
end

-- ============ ME323兵力運輸 ============
-- 音效：me323_engine (2秒，迴圈播放)
function AirSupport.CallME323Military(targetHelipadX, targetHelipadY)
  if not AirSupport.IsAvailable("me323_military") then
    return false, "ME323正在冷卻中...剩餘 " .. cooldowns.me323_military .. " 秒"
  end
  
  cooldowns.me323_military = CONFIG.ME323_COOLDOWN
  return true, "ME323兵力運輸機已調度！120名精英士兵即將空投到指定位置。"
end

-- ============ 任務執行更新 ============
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
    
    -- 任務完成
    if mission.progress >= mission.totalFrames then
      table.insert(completedMissions, missionID)
    end
  end
  
  -- 移除已完成的任務
  for _, missionID in ipairs(completedMissions) do
    activeMissions[missionID] = nil
  end
end

-- ============ 斯圖卡任務步驟 ============
-- 時間分配（32秒總時長）：
-- 0-10秒（30%）：接近目標 - 播放 stuka_dive (30秒)
-- 10-16秒（50%）：轟炸投彈 - 播放 stuka_bomb (2秒)
-- 16-32秒（100%）：離開地圖
function AirSupport.UpdateStukaMission(mission, progress_ratio)
  if progress_ratio < 0.3 then
    -- 階段1：接近（0-10秒）
    mission.state = "incoming"
    mission.currentX = mission.startX + (mission.targetX - mission.startX) * (progress_ratio / 0.3)
    mission.currentY = mission.startY
    
    -- 播放俯衝音效（第一次）
    if not mission.soundStarted then
      -- PlaySound("sounds/stuka_dive", mission.currentX, mission.currentY)
      mission.soundStarted = true
    end
    
  elseif progress_ratio < 0.5 then
    -- 階段2：轟炸（10-16秒）
    mission.state = "bombing"
    mission.currentX = mission.targetX
    mission.currentY = mission.targetY
    
    -- 播放投彈音效（第一次到達轟炸點）
    if not mission.bombStarted then
      -- PlaySound("sounds/stuka_bomb", mission.targetX, mission.targetY)
      AirSupport.ExecuteStukaBomb(mission.targetX, mission.targetY)
      mission.bombStarted = true
    end
    
  else
    -- 階段3：離開（16-32秒）
    mission.state = "departing"
    local departProgress = (progress_ratio - 0.5) / 0.5
    mission.currentX = mission.targetX + (500 - mission.targetX) * departProgress
    mission.currentY = mission.targetY
  end
end

-- 執行斯圖卡轟炸傷害
function AirSupport.ExecuteStukaBomb(bombX, bombY)
  -- 遊戲引擎集成點
  -- CreateExplosion(bombX, bombY, CONFIG.STUKA_RADIUS, CONFIG.STUKA_DAMAGE, true)
  -- DamageObjectsInRadius(bombX, bombY, CONFIG.STUKA_RADIUS * 2, CONFIG.STUKA_DAMAGE, "fire")
end

-- ============ Me262任務步驟 ============
-- 時間分配（4秒總時長）：
-- 0-1秒（25%）：接近目標 - 播放 me262_jet (1秒)
-- 1-4秒（75%）：掃射 - 播放 me262_mg (3秒)
-- 4-4秒（100%）：離開地圖
function AirSupport.UpdateMe262Mission(mission, progress_ratio)
  if progress_ratio < 0.25 then
    -- 階段1：接近（0-1秒）
    mission.state = "incoming"
    mission.currentX = mission.startX + (mission.endX - mission.startX) * (progress_ratio / 0.25)
    mission.currentY = mission.startY
    
    -- 播放喷氣音效
    if not mission.soundStarted then
      -- PlaySound("sounds/me262_jet", mission.currentX, mission.currentY)
      mission.soundStarted = true
    end
    
  elseif progress_ratio < 1.0 then
    -- 階段2：掃射（1-4秒）
    mission.state = "strafing"
    mission.currentX = mission.startX + (mission.endX - mission.startX) * ((progress_ratio - 0.25) / 0.75)
    mission.currentY = mission.startY
    
    -- 持續播放機炮音效（me262_mg 3秒會迴圈）
    if progress_ratio >= 0.25 and progress_ratio < 1.0 then
      AirSupport.ExecuteMe262Strafe(mission)
    end
    
  else
    -- 階段3：離開地圖
    mission.state = "departing"
    mission.currentX = mission.endX + 50
    mission.currentY = mission.endY
  end
end

-- 執行Me262掃射傷害
function AirSupport.ExecuteMe262Strafe(mission)
  -- 遊戲引擎集成點
  -- CreateStrafeLine(mission.startX, mission.startY, mission.endX, mission.endY, CONFIG.ME262_DAMAGE)
  -- SuppressObjectsInLine(mission.startX, mission.startY, mission.endX, mission.endY, CONFIG.ME262_DAMAGE)
end

-- ============ 對外接口 ============
function AirSupport.GetStatus()
  return {
    stuka_available = AirSupport.IsAvailable("stuka"),
    stuka_cooldown = cooldowns.stuka,
    stuka_description = "俯衝轟炸 - 冷卻:" .. cooldowns.stuka .. "秒",
    
    me262_available = AirSupport.IsAvailable("me262"),
    me262_cooldown = cooldowns.me262,
    me262_description = "噴氣掃射 - 冷卻:" .. cooldowns.me262 .. "秒",
    
    me323_available = AirSupport.IsAvailable("me323_military"),
    me323_cooldown = cooldowns.me323_military,
    me323_description = "兵力空投 - 冷卻:" .. cooldowns.me323_military .. "秒",
    
    active_missions = #activeMissions,
    mission_count = missionCounter
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
      progressPercent = math.floor((mission.progress / mission.totalFrames) * 100),
      timeRemaining = math.ceil((mission.totalFrames - mission.progress) / 60) .. "秒"
    })
  end
  return missionList
end

-- 獲取音效信息（用於調試）
function AirSupport.GetSoundConfig()
  return {
    stuka_dive = CONFIG.STUKA_DIVE_DURATION .. "秒",
    stuka_bomb = CONFIG.STUKA_BOMB_DURATION .. "秒",
    stuka_total = (CONFIG.STUKA_DIVE_DURATION + CONFIG.STUKA_BOMB_DURATION) .. "秒",
    
    me262_jet = CONFIG.ME262_JET_DURATION .. "秒",
    me262_mg = CONFIG.ME262_MG_DURATION .. "秒",
    me262_total = (CONFIG.ME262_JET_DURATION + CONFIG.ME262_MG_DURATION) .. "秒",
    
    me323_engine = CONFIG.ME323_ENGINE_DURATION .. "秒（迴圈）"
  }
end

-- ============ 主更新函數 ============
function AirSupport.Update(deltaTime)
  AirSupport.UpdateCooldowns()
  AirSupport.UpdateMissions()
end

return AirSupport
