MathLib = {}
setmetatable(MathLib, {
    __index = _G
})
_ENV = MathLib

--[[
    Вычисляет угол направления от startPoint2D к endPoint2D в радианах.
    Возвращает значение в диапазоне [0, 2π).
    Угол отсчитывается от положительного направления оси X против часовой стрелки.
    
    Аргументы:
        startPoint2D - начальная точка (Point2D)
        endPoint2D   - конечная точка (Point2D)
    Возвращает:
        угол в радианах (number)
]]
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

--[[
    Создаёт вектор направления от startPoint к endPoint в плоскости XY.
    
    Аргументы:
        startPoint - начальная точка (Point2D или Point3D)
        endPoint   - конечная точка (Point2D или Point3D)
    Возвращает:
        Vector3D с компонентами (dx, dy, 0)
]]
function DirectionVector2D(startPoint, endPoint)
    return Vector3D(
        endPoint:GetX() - startPoint:GetX(),
        endPoint:GetY() - startPoint:GetY(),
        0
    )
end

--[[
    Вычисляет евклидово расстояние между двумя точками на плоскости.
    
    Аргументы:
        startPoint2D - первая точка (Point2D)
        endPoint2D   - вторая точка (Point2D)
    Возвращает:
        расстояние (number)
]]
function Distance2D(startPoint2D, endPoint2D)
    local x = endPoint2D:GetX() - startPoint2D:GetX()
    local y = endPoint2D:GetY() - startPoint2D:GetY()
    return math.sqrt(x ^ 2 + y ^ 2)
end

--[[
    Проецирует 3D-точку на плоскость XY, отбрасывая координату Z.
    
    Аргументы:
        point - трёхмерная точка (Point3D)
    Возвращает:
        двумерная точка (Point2D) с координатами (x, y)
]]
function ProjectPoint3Dto2D(point)
    return Point2D(point:GetX(), point:GetY())
end

--[[
    Сдвигает геометрический объект вдоль вектора на заданную длину.
    
    Аргументы:
        object - объект с методом Shift (Point3D, Curve3D и т.д.)
        vector - направление сдвига (Vector3D)
        length - длина сдвига (number)
    Возвращает:
        сдвинутый объект (того же типа, что и на входе)
]]
function ShiftedByVector(object, vector, length)
    return object:Shift(
        vector:GetX() * length,
        vector:GetY() * length,
        vector:GetZ() * length
    )
end

--[[
    Генерирует массив точек по периметру прямоугольника.
    Используется для создания контурной арматуры (хомутов).
    
    Аргументы:
        length   - длина прямоугольника (по оси X)
        width    - ширина прямоугольника (по оси Y)
        n_lenght - количество точек по длине (включая углы)
        n_width  - количество точек по ширине (включая углы)
    Возвращает:
        таблица с точками Point3D, начиная с левого нижнего угла,
        обход по часовой стрелке
]]
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

--[[
    Генерирует массив точек по окружности.
    Используется для создания кольцевой арматуры.
    
    Аргументы:
        diameter - диаметр окружности
        n        - количество точек
        angle    - начальный угол поворота (в радианах)
    Возвращает:
        таблица с точками Point3D, равномерно распределёнными по окружности
]]
function CircleBorderPoint3DArray(diameter, n, angle)
    local points = {Point3D(-diameter / 2, 0, 0):Rotate(CreateZAxis3D(), angle)}
    local arrayAngle = math.pi * 2 / n
    for i = 1, n - 1 do
        table.insert(points, points[1]:Clone():Rotate(CreateZAxis3D(), arrayAngle * i))
    end
    return points
end

--[[
    Получает диаметр арматурного стержня по его стилю из проекта.
    
    Аргументы:
        rebarStyleId - идентификатор стиля арматуры
    Возвращает:
        диаметр стержня (number) в миллиметрах
]]
function GetRebarDiameter(rebarStyleId)
    local style = Project.GetRebarStyle(rebarStyleId)
    return style:GetParameterValues().Diameter
end

--[[
    Получает радиус арматурного стержня по его стилю из проекта.
    
    Аргументы:
        rebarStyleId - идентификатор стиля арматуры
    Возвращает:
        радиус стержня (number) в миллиметрах
]]
function GetRebarRadius(rebarStyleId)
    local style = Project.GetRebarStyle(rebarStyleId)
    return style:GetParameterValues().Diameter / 2
end

--[[
    Вычисляет угол между двумя векторами, заданными тремя точками.
    Угол между векторами (p1->p2) и (p2->p3).
    
    Аргументы:
        p1, p2, p3 - точки (Point2D или Point3D)
    Возвращает:
        угол в радианах (number)
]]
function AngleBetweenVectors(p1, p2, p3)
    local v1 = DirectionVector2D(p1, p2)
    local v2 = DirectionVector2D(p2, p3)
    local dot = v1:GetX() * v2:GetX() + v1:GetY() * v2:GetY()
    local len1 = math.sqrt(v1:GetX()^2 + v1:GetY()^2)
    local len2 = math.sqrt(v2:GetX()^2 + v2:GetY()^2)
    return math.acos(dot / (len1 * len2))
end

--[[
    Создаёт точку, сдвинутую под углом 45°.
    Используется для построения скруглений в хомутах.
    
    Аргументы:
        point     - исходная точка (Point3D)
        distance  - расстояние смещения
        direction - направление (1 или -1)
    Возвращает:
        Point3D
]]
function ShiftDiagonal45(point, distance, direction)
    local d = distance * math.cos(math.pi / 4)
    return point:Clone():Shift(d * direction, d * direction, 0)
end