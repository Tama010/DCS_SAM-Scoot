local _debugMode = false

-- デバッグモードでメッセージをゲーム画面に出力
function outText(message)
    if _debugMode then
        trigger.action.outText(message, 3, false)
    end
end

function avoidanceBomb()
    local _obj = {}
    local _bombList = {}

    local _COALITIONSIDERED = 1
    local _COALITIONSIDEBLUE = 2
    local _BOMBWEAPONCATEGORY = 3
    local _OPARATIONALTARGETKEYWORD = "scoot"
    local _REPETATIONTIME = 5
    local _DETECTRANGE = 15000
    local _GIVEUPRANGE = 1000
    local _ERRORDISTANCE = 999

    local _scootGrpList = {}
    local _scootGrpListQueue = {} 
    local _counter = 1

    function _obj:onEvent(event)
        
        if event.id == world.event.S_EVENT_SHOT then
            local _weapon = event.weapon
            if event.weapon:getDesc().category == _BOMBWEAPONCATEGORY then
                table.insert(_bombList, event.weapon)
            end
        end
    end

    function _obj:judgePositionChange()

        -- 準備
        local _bombListForJudgement = createBombList()
        local _grpList = getOparationalTargetGroup()

        -- 判断
        for _, _grp in pairs(_grpList) do
            outText("対象グループ名：".. _grp:getName())
            for _, _bomb in pairs(_bombListForJudgement) do
                if isBombThreat(_bomb, _grp) then
                    oparateScootFlag(_bomb, _grp)
                end
            end
        end

        -- 実行
        for _i, _scootFlagStockObj in pairs(_scootGrpList) do
            if _scootFlagStockObj['scootFlag3'] and not _scootFlagStockObj['alreadyScooted']then
                scoot(_scootGrpList[_i])
            end

        end


        timer.scheduleFunction(self.judgePositionChange, self, timer.getTime() + _REPETATIONTIME)
    end

    -- 判断用のボムリストを生成
    function createBombList()
        
        -- 爆弾リストをコピー
        local _bombListForJudgement = _bombList

        -- 存在しない爆弾を除外
       for _i, _bomb in pairs(_bombListForJudgement) do
            if not _bomb:isExist() then
                table.remove(_bombListForJudgement, _i)    
            end
       end

        return _bombListForJudgement
    end

    -- 対象グループを取得
    function getOparationalTargetGroup()

        local _oparationalTargetGroupList = {}

        for _coalitionSideNum = _COALITIONSIDERED, _COALITIONSIDEBLUE do
            for _i, _grp in pairs(coalition.getGroups(_coalitionSideNum)) do
                if string.find(_grp:getName(), _OPARATIONALTARGETKEYWORD) then
                    table.insert(_oparationalTargetGroupList, _grp)
                end
            end
        end

        return _oparationalTargetGroupList
    end

    -- 脅威判定
    function isBombThreat(_bomb, _grp)

        if not _grp:isExist() then
            return false
        end

        -- 脅威判定の事前条件
        -- レーダーは使用中か
        if not isActivatingRadar(_grp) then
            outText("    レーダー非稼働")
            return false
        end

        -- 爆弾は探知圏内か
        if not canDetectBomb(_bomb, _grp) then
            return false
        end

        outText("    脅威を探知")

        -- 接近中か
        if not isHot(_bomb, _grp) then
            return false
        end

        -- 脅威判定
        -- 爆弾は直撃コースか
        if not isDirectHitCourse(_bomb, _grp) then
            return false
        end
        
        return true
    end

    -- レーダーを使用中か
    function isActivatingRadar(_grp)
        if not _grp:isExist() then
            return false
        end
        for _, _unit in pairs(_grp:getUnits()) do
            if not _unit:isExist() then
                return false
            end
            if _unit:getRadar() then
                return true
            end
        end

        return false
    end

    -- 接近中か
    function isHot(_bomb, _grp) 
		if not _grp:isExist() then
            
            return false
        end
        for _, _unit in pairs(_grp:getUnits()) do
            if not _unit:isExist() then
                   return false
            end
            if _unit:getRadar() then
                local _grpPosition = _unit:getPoint()
                if not _bomb:isExist() then
                    return false
                end
                local _bombPosition = _bomb:getPoint()
                local _bombVelocity = _bomb:getVelocity()
        
                local _hotXFlag = false
        
                if _bombVelocity.x >=0 then
                    if _bombPosition.x < _grpPosition.x then
                        _hotXFlag = true
                    end
                else
                    if _bombPosition.x > _grpPosition.x then
                        _hotXFlag = true
                    end
                end
                
                if _hotXFlag then
                    if _bombVelocity.z >=0 then
                        if _bombPosition.z < _grpPosition.z then
                            return true
                        end
                    else
                        if _bombPosition.z > _grpPosition.z then
                            return true
                        end
                    end
                end
            end
        end
		return false
    end

    -- レーダー停止の場合、退避フラグをリセット
    function resetScootFlag(_grp)
        for _i, _obj in pars(_scootGrpList) do
            if _obj['grp'] == _grp then
                _obj['scootFlag1'] = false
                _obj['scootFlag2'] = false
                _obj['scootFlag3'] = false
            end
        end
    end

    -- 探知圏内か判別
    function canDetectBomb(_bomb, _grp)
        -- レーダー車両と爆弾の距離で判断
        if not _bomb:isExist() then
            return false
        end

        local _bombPosition = _bomb:getPoint()
        if not _grp:isExist() then
            return false
        end
        for _, _unit in pairs(_grp:getUnits()) do
            if not _unit:isExist() then
                return false
            end
            if _unit:getRadar() then
                local _radarPosition = _unit:getPoint()
                local _distance = math.sqrt((_radarPosition.x - _bombPosition.x)^2 + (_radarPosition.y - _bombPosition.y)^2 + (_radarPosition.z - _bombPosition.z)^2)
                -- ついでに退避可能な距離かも判別
                if _distance < _DETECTRANGE and _distance > _GIVEUPRANGE then
                    return true
                end
            end
        end

        return false
        
    end

    -- 直撃コースか
    function isDirectHitCourse(_bomb, _grp)

        return culcFlyPass(_bomb, _grp)

    end



    -- 飛翔経路を算出
    function culcFlyPass(_bomb, _grp)
        if not _bomb:isExist() then
            return false
        end

        velocity = _bomb:getVelocity()
        x, z  = vec2dNormalize(velocity.x,velocity.z)

        -- 2次元方程式を算出
        -- y = ax + b
        -- 傾きと爆弾の座標はある
        -- bを算出
        local _bombPosition = _bomb:getPoint()
        local _b = _bombPosition.z - z/x * _bombPosition.x

        -- グループの位置
        if not _grp:isExist() then
            return false
        end
        for _, _unit in pairs(_grp:getUnits()) do
            if not _unit:isExist() then
                return false
            end

            if _unit:getRadar() then
                local _radarPosition = _unit:getPoint()

                local y = z/x * _radarPosition.x + _b

                -- 2点の距離
                -- 予想飛翔経路の座標と実物の座標の比較
                local _distance = math.sqrt((y - _radarPosition.z)^2)
                outText("        予想飛翔経路との誤差".. _distance)

                if _distance < _ERRORDISTANCE then
                    outText("        直撃コース")
                    return true
                end
                outText("        外れるコース")
            end
        end

        return false

    end

    -- 2次元ベクトルの正規化
    function vec2dNormalize(x,z)
        local length = math.sqrt((x * x) + (z * z))
        if length > 0 then
            length = 1 / length
        end
        return x * length, z * length 
    end

    -- 回避フラグの操作
    function oparateScootFlag(_bomb, _grp)

        if #_scootGrpList == 0 then
            table.insert(_scootGrpList, createScootFlagStockObj(_bomb, _grp))
            return
        end

        changeScootFlag(_bomb, _grp)

    end

    -- 回避フラグを持つインスタンスの生成
    function createScootFlagStockObj(_bomb, _grp)
        local _scootFlagStockObj = {
            ['bomb'] = _bomb,
            ['grp'] = _grp,
            ['alreadyScooted'] = false,
            ['scootFlag1'] = true,
            ['scootFlag2'] = false,
            ['scootFlag3'] = false,
        }

        return _scootFlagStockObj
    end

    -- フラグ操作
    function changeScootFlag(_bomb, _grp)
        
        for _, _obj in pairs(_scootGrpList) do

            if _obj['bomb'] == _bomb and _obj['grp'] == _grp then
                
                -- 回避済みなら無視
                if _obj['alreadyScooted'] then
                    return
                end

                if _obj['scootFlag1'] then
                    if _obj['scootFlag2'] then
                        _obj['scootFlag3'] = true
                        outText("    陣地転換開始")
                    else
                        _obj['scootFlag2'] = true
                    end
                else
                    _obj['scootFlag1'] = true
                end
                return
            end
        end
        table.insert(_scootGrpList, createScootFlagStockObj(_bomb, _grp))
        return 

    end

    -- 回避開始
    function scoot(_scootFlagStockObj)

        -- フラグ初期化
        _scootFlagStockObj['alreadyScooted'] = true

        -- アラートステートをグリーン
        -- 射撃したランチャーは一度GREENにしても動かない
        -- REDとGREENを何回か切りけると動くようになる
        -- 本当はこんなことしたくない...
        table.insert(_scootGrpListQueue, _scootFlagStockObj['grp'])
        timer.scheduleFunction(changeAlertGreen1, id, timer.getTime() + 1)
        timer.scheduleFunction(changeAlertRed2, id, timer.getTime() + 5)
        --timer.scheduleFunction(changeAlertGreen1, id, timer.getTime() + 8)
        --timer.scheduleFunction(changeAlertRed2, id, timer.getTime() + 9)
        timer.scheduleFunction(changeAlertGreen3, id, timer.getTime() + 10)

    end

    -- アラートステータスをREDに変更
    function changeAlertGreen1()
        if _scootGrpListQueue[_counter]:isExist() then
            local _grp = _scootGrpListQueue[_counter]
            local _grpController = _grp:getController()
            Controller.setOption(_grp, AI.Option.Ground.id.ALARM_STATE, AI.Option.Ground.val.ALARM_STATE.GREEN)
        end
    end

    -- アラートステータスをGREENに変更
    function changeAlertRed2()
        if _scootGrpListQueue[_counter]:isExist() then
            local _grp = _scootGrpListQueue[_counter]
            local _grpController = _grp:getController()
            Controller.setOption(_grp, AI.Option.Ground.id.ALARM_STATE, AI.Option.Ground.val.ALARM_STATE.RED)
        end
    end

    -- アラートステータスをREDに変更
    function changeAlertGreen3()
        if _scootGrpListQueue[_counter]:isExist() then
            local _grp = _scootGrpListQueue[_counter]
            local _grpController = _grp:getController()
            Controller.setOption(_grp, AI.Option.Ground.id.ALARM_STATE, AI.Option.Ground.val.ALARM_STATE.GREEN)
        end
        _counter = _counter + 1
    end


    return _obj
end



_instance = avoidanceBomb()
world.addEventHandler(_instance)
_instance:judgePositionChange()