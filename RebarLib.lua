require "MathLib"

RebarLib = {}
setmetatable(RebarLib, {
    __index = _G
})
_ENV = RebarLib

function CreateRebarLayout(rebarStyleId, curve3D, fullLength, step, vector)
    local rebar_radius = MathLib.GetRebarRadius(rebarStyleId)
    local number = math.floor((fullLength - rebar_radius * 2) / step)
    local start_shift = (fullLength - step * number) / 2
    MathLib.ShiftedByVector(curve3D, vector, start_shift)
    number = number + 1
    if number < 5 then
        for i = 1, number do
            Style.AddRebar(rebarStyleId, curve3D)
            ShiftedByVector(curve3D, vector, step)
        end
    else
        Style.AddRebarSet(rebarStyleId, curve3D, vector, step, number)
    end
end

function CreateRebarLayoutWithFreeEnd(rebarStyleId, curve3D, fullLength, freeEnd, step, vector)
    local rebar_radius = MathLib.GetRebarRadius(rebarStyleId)
    local length = fullLength - freeEnd * 2
    local number = math.floor(length / step)
    local last_step = length - step * number

    if last_step < rebar_radius * 2 then
        number = number - 1
    end

    MathLib.ShiftedByVector(curve3D, vector, freeEnd)
    number = number + 1
    if number < 5 then
        local curve = curve3D:Clone()
        for i = 1, number do
            Style.AddRebar(rebarStyleId, curve)
            MathLib.ShiftedByVector(curve, vector, step)
        end
    else
        Style.AddRebarSet(rebarStyleId, curve3D, vector, step, number)
    end
    MathLib.ShiftedByVector(curve3D, vector, length)
    Style.AddRebar(rebarStyleId, curve3D)
end

function SpiralRebarByStep(point3d, radius, step, n, rebarStyleId)
    local axis = Axis3D(point3d, Vector3D(0, 0, 1))
    local curves = {}
    for i = 0, n - 1 do
        local points = {point3d:Clone():Shift(radius, 0, 0)}
        for j = 1, 4 do
            table.insert(points, points[1]:Clone():Rotate(axis, math.pi / 2 * j):Shift(0, 0, step * 0.25 * j))
        end
        local composite = CreateCompositeCurve3D({CreateArc3DByThreePoints(points[1], points[2], points[3]),
                                                  CreateArc3DByThreePoints(points[3], points[4], points[5])})
        table.insert(curves, composite:Shift(0, 0, step * i))
    end
    Style.AddRebar(rebarStyleId, CreateCompositeCurve3D(curves))
end

function SpiralRebarByHeight(point3d, radius, step, height, rebarStyleId)
    local dRebar = MathLib.GetRebarDiameter(rebarStyleId)
    local axis = Axis3D(point3d, Vector3D(0, 0, 1))
    local numberRem = height / step
    local intNumber, fractNumber = math.modf(height / step)

    function spiralTwist(step, shiftZ)
        local startPoint = point3d:Clone():Shift(radius, 0, 0)
        local points = {startPoint}
        for j = 1, 4 do
            table.insert(points, points[1]:Clone():Rotate(axis, math.pi / 2 * j):Shift(0, 0, step * 0.25 * j))
        end
        local composite = CreateCompositeCurve3D({CreateArc3DByThreePoints(points[1], points[2], points[3]),
                                                  CreateArc3DByThreePoints(points[3], points[4], points[5])})
        return composite:Shift(0, 0, shiftZ)
    end

    local curves = {}
    local lastFactor = 1

    if intNumber >= 1 then
        if intNumber >= 2 then
            for i = 0, intNumber - 2 do
                table.insert(curves, spiralTwist(step, step * i))
            end
        end

        if 0 < step * fractNumber and step * fractNumber < dRebar then
            lastFactor = fractNumber + 1
        end

        table.insert(curves, spiralTwist(step * lastFactor, step * (intNumber - 1)))

        if step * fractNumber >= dRebar and intNumber > 1 then
            table.insert(curves, spiralTwist(step * fractNumber, step * intNumber))
        end

        Style.AddRebar(rebarStyleId, CreateCompositeCurve3D(curves))
    end
end

