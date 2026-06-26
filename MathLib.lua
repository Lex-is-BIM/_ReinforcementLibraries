MathLib = {}
setmetatable(MathLib, {
    __index = _G
})
_ENV = MathLib

function DirectionAngle(startPoint2D, endPoint2D)
    local dx = endPoint2D:GetX() - startPoint2D:GetX()
    local dy = endPoint2D:GetY() - startPoint2D:GetY()

    if dx == 0 then
        return dy >= 0 and math.pi / 2 or 3 * math.pi / 2
    end

    local arrayAngle = math.atan(math.abs(dy) / math.abs(dx))

    if dx > 0 then
        return dy >= 0 and arrayAngle or 2 * math.pi - arrayAngle
    else
        return dy >= 0 and math.pi - arrayAngle or math.pi + arrayAngle
    end
end

function Distance2D(startPoint2D, endPoint2D)
    local x = endPoint2D:GetX() - startPoint2D:GetX()
    local y = endPoint2D:GetY() - startPoint2D:GetY()
    return math.sqrt(x ^ 2 + y ^ 2)
end

function ProjectPoint3Dto2D(point)
    return Point2D(point:GetX(), point:GetY())
end

function ShiftedByVector(object, vector, length)
    return object:Shift(vector:GetX() * length, vector:GetY() * length, vector:GetZ() * length)
end

function RectBorderPoint3DArray(length, width, n_lenght, n_width)
    local startPoint = Point3D(-length / 2, -width / 2, 0)
    local lenghtSnap = length / (n_lenght - 1)
    local widthSnap = width / (n_width - 1)
    local longRebarsPoints = {startPoint}
    for i = 1, n_width - 1 do
        table.insert(longRebarsPoints, startPoint:Clone():Shift(0, widthSnap * i, 0))
    end
    for i = 1, n_lenght - 1 do
        table.insert(longRebarsPoints, startPoint:Clone():Shift(lenghtSnap * i, width, 0))
    end
    for i = 1, n_width - 1 do
        table.insert(longRebarsPoints, startPoint:Clone():Shift(length, width, 0):Shift(0, -widthSnap * i, 0))
    end
    for i = 1, n_lenght - 1 do
        table.insert(longRebarsPoints, startPoint:Clone():Shift(length, 0, 0):Shift(-lenghtSnap * i, 0, 0))
    end
    return longRebarsPoints
end

function CircleBorderPoint3DArray(diameter, n, angle)
    local points = {Point3D(-diameter / 2, 0, 0):Rotate(CreateZAxis3D(), angle)}
    local arrayAngle = math.pi * 2 / n
    for i = 1, n - 1 do
        table.insert(points, points[1]:Clone():Rotate(CreateZAxis3D(), arrayAngle * i))
    end
    return points
end

function GetRebarDiameter(rebarStyleId)
    local style = Project.GetRebarStyle(rebarStyleId)
    return style:GetParameterValues().Diameter
end

function GetRebarRadius(rebarStyleId)
    local style = Project.GetRebarStyle(rebarStyleId)
    return style:GetParameterValues().Diameter / 2
end

