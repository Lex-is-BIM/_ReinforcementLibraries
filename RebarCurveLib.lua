require "MathLib"

RebarCurveLib = {}
setmetatable(RebarCurveLib, {
    __index = _G
})
_ENV = RebarCurveLib

--[[
    Создаёт C-образный хомут (скобу) между двумя точками.
    
    Форма: прямая часть с двумя загнутыми концами в одну сторону.
    
    Аргументы:
        startPoint2D     - начальная точка (Point2D)
        endPoint2D       - конечная точка (Point2D)
        bendLengthD      - длина загиба в диаметрах стержня
        rebarStyleId     - идентификатор стиля поперечной арматуры
        longRebarStyleId - идентификатор стиля продольной арматуры
    Возвращает:
        кривая 3D (Curve3D)
]]
function C_ClampCurve(startPoint2D, endPoint2D, bendLengthD, rebarStyleId, longRebarStyleId)
    local longR = MathLib.GetRebarRadius(longRebarStyleId)
    local r = MathLib.GetRebarRadius(rebarStyleId)
    local length = MathLib.Distance2D(startPoint2D, endPoint2D)
    local rBending = (longR < 2.5 * r) and (3.5 * r) or (longR + r)
    local lBend = bendLengthD * r * 2 + rBending
    local shiftX = longR + r
    local angle = MathLib.DirectionAngle(startPoint2D, endPoint2D)
    local startPoint = Point3D(startPoint2D:GetX(), startPoint2D:GetY(), 0)
    local points = {startPoint:Clone():Shift(-shiftX + lBend, rBending, 0),
                    startPoint:Clone():Shift(-shiftX, rBending, 0), startPoint:Clone():Shift(-shiftX, -rBending, 0),
                    startPoint:Clone():Shift(length + shiftX, -rBending, 0),
                    startPoint:Clone():Shift(length + shiftX, rBending, 0),
                    startPoint:Clone():Shift(length + shiftX - lBend, rBending, 0)}

    local rebarCurve = CreatePolyline3D(points)
    FilletCorners3D(rebarCurve, rBending)
    return rebarCurve:Rotate(Axis3D(startPoint, Vector3D(0, 0, 1)), angle)
end

--[[
    Создаёт S-образный хомут (скобу) между двумя точками.
    
    Форма: два полукруглых изгиба в противоположные стороны.
    
    Аргументы:
        startPoint2D     - начальная точка (Point2D)
        endPoint2D       - конечная точка (Point2D)
        bendLengthD      - длина загиба в диаметрах стержня
        rebarStyleId     - идентификатор стиля поперечной арматуры
        longRebarStyleId - идентификатор стиля продольной арматуры
    Возвращает:
        кривая 3D (Curve3D)
]]
function S_ClampCurve(startPoint2D, endPoint2D, bendLengthD, rebarStyleId, longRebarStyleId)
    local longR = MathLib.GetRebarRadius(longRebarStyleId)
    local r = MathLib.GetRebarRadius(rebarStyleId)

    local length = MathLib.Distance2D(startPoint2D, endPoint2D)
    local rBending = (longR < 2.5 * r) and (3.5 * r) or (longR + r)
    local lBend = bendLengthD * r * 2
    local shiftXCenterLine = 2.5 * r - longR
    local length2 = length - shiftXCenterLine * 2

    local tangentAngle = math.acos(rBending / (length2 * 0.5))
    local shiftX = math.cos(tangentAngle) * rBending
    local shiftY = math.sin(tangentAngle) * rBending
    local shiftBendX = math.sin(tangentAngle) * lBend
    local shiftBendY = math.cos(tangentAngle) * lBend

    local startPoint = Point3D(startPoint2D:GetX(), startPoint2D:GetY(), 0)

    local points = {startPoint:Clone():Shift(shiftXCenterLine - shiftX + shiftBendX, shiftY + shiftBendY, 0),
                    startPoint:Clone():Shift(shiftXCenterLine - shiftX - shiftY, shiftY - shiftX, 0),
                    startPoint:Clone():Shift(shiftXCenterLine + shiftX - shiftY, -shiftY - shiftX, 0),
                    startPoint:Clone():Shift(length - shiftXCenterLine - shiftX + shiftY, shiftY + shiftX, 0),
                    startPoint:Clone():Shift(length - shiftXCenterLine + shiftX + shiftY, -shiftY + shiftX, 0),
                    startPoint:Clone():Shift(length - shiftXCenterLine + shiftX - shiftBendX, -shiftY - shiftBendY, 0)}

    local rebarCurve = CreatePolyline3D(points)
    FilletCorners3D(rebarCurve, rBending)

    local angle = MathLib.DirectionAngle(startPoint2D, endPoint2D)
    return rebarCurve:Rotate(Axis3D(startPoint, Vector3D(0, 0, 1)), angle)
end

--[[
    Создаёт замкнутый прямоугольный хомут (O-образный).
    
    Форма: прямоугольная рамка с загибами в углах.
    
    Аргументы:
        point3D          - опорная точка (левый нижний угол, Point3D)
        width            - ширина хомута (по оси X)
        depth            - глубина хомута (по оси Y)
        angle            - угол поворота хомута в плоскости XY (радианы)
        bendLengthD      - длина загиба в диаметрах стержня
        rebarStyleId     - идентификатор стиля поперечной арматуры
        longRebarStyleId - идентификатор стиля продольной арматуры
    Возвращает:
        кривая 3D (Curve3D)
]]
function O_ClampCurveByPointAndAngle(point3D, width, depth, angle, bendLengthD, rebarStyleId, longRebarStyleId)
    local longR = MathLib.GetRebarRadius(longRebarStyleId)
    local r = MathLib.GetRebarRadius(rebarStyleId)
    local rBending = math.max(3.5 * r, longR + r)
    local lBend = bendLengthD * r * 2
    local shiftCenterPoint = 2.5 * r - longR
    local shiftCenterPointXY = math.sqrt(0.5 * shiftCenterPoint * shiftCenterPoint)
    local widthClampCenterPoint = width - shiftCenterPointXY * 2
    local depthClampCenterPoint = depth - shiftCenterPointXY * 2
    local centerPoint = point3D:Clone():Shift(shiftCenterPointXY, shiftCenterPointXY, 0)
    local axis = Axis3D(centerPoint, Vector3D(0, 0, 1))
    local rotateAxis = Axis3D(point3D, Vector3D(0, 0, 1))

    local function createPoint(sx, sy, sz, angle)
        return centerPoint:Clone():Shift(sx, sy, sz):Rotate(axis, angle)
    end

    local startPoints = {createPoint(-rBending, lBend, 0, -math.pi / 4), createPoint(-rBending, 0, 0, -math.pi / 4),
                         createPoint(0, -rBending, 0, 0)}
    local middlePoints = {createPoint(widthClampCenterPoint + rBending, -rBending, 0, 0),
                          createPoint(widthClampCenterPoint + rBending, depthClampCenterPoint + rBending, r * 2, 0),
                          createPoint(-rBending, depthClampCenterPoint + rBending, r * 2, 0),
                          createPoint(-rBending, 0, r * 2, 0)}

    local endPoints = {createPoint(-rBending, 0, r * 2, 0.75 * math.pi),
                       createPoint(-rBending, -lBend, r * 2, 0.75 * math.pi)}

    local startBend = CreateCompositeCurve3D({CreateLineSegment3D(startPoints[1], startPoints[2]),
                                              CreateArc3DByCenterStartEndPoints(centerPoint, startPoints[2],
        startPoints[3], false)})

    local middlePolyline = CreatePolyline3D({startPoints[3], middlePoints[1], middlePoints[2], middlePoints[3],
                                             middlePoints[4]})
    FilletCorners3D(middlePolyline, rBending)

    local endBend = CreateCompositeCurve3D({CreateArc3DByCenterStartEndPoints(centerPoint:Clone():Shift(0, 0, 2 * r),
        middlePoints[4], endPoints[1], false), CreateLineSegment3D(endPoints[1], endPoints[2])})
    return CreateCompositeCurve3D({startBend, middlePolyline, endBend}):Rotate(rotateAxis, angle)
end