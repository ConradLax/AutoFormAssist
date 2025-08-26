#Requires AutoHotkey v2.0

GetAreaAroundCenter(cx, cy, virtualX, virtualY, &dimensionsX, &dimensionsY) {

    ; Coords of x and y of where the scan image is going to start
    coordX := cx - dimensionsX // 2
    coordY := cy - dimensionsY // 2

    ; Recalculate coordX and new width if coordX goes out of boundary of user screen
    if(coordX < 0) {
        tempX := dimensionsX - 2 * Abs(coordX)
        dimensionsX := Abs(tempX)
        coordX := Abs(coordX - dimensionsX)
    }
    
    if((coordX + dimensionsX) > virtualX) {
        tempCoordX := coordX + dimensionsX - virtualX
        tempX := dimensionsX - 2 * Abs(tempCoordX)
        dimensionsX := Abs(tempX)
        coordX := Abs(coordX - tempCoordX)
    }

    ; Recalculate coordY and new height if coordY goes out of boundary of user screen
    if(coordY < 0) {
        tempY := dimensionsY - 2 * Abs(coordY)
        dimensionsY := Abs(tempY)
        coordY := Abs(coordY - dimensionsY)
    }

    if((coordY + dimensionsY) > virtualY) {
        tempCoordY := coordY + dimensionsY - virtualY
        tempY := dimensionsY - 2 * Abs(tempCoordY)
        dimensionsY := Abs(tempY)
        coordY := Abs(coordY - tempCoordY)
    }

    return [coordX, coordY, dimensionsX, dimensionsY]
}