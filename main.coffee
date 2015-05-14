
# Location of the top of the pendulum
X0 = 400
Y0 = 300
g  = 9.8
time = 0.05

canvas  = document.getElementById('simulation')
context = canvas.getContext('2d')

drawLine = (x1, y1, x2, y2) =>
    context.strokeStyle = 'rgba(0, 0, 0, 0.2)'
    context.beginPath()
    context.moveTo(x1, y1)
    context.lineTo(x2, y2)
    context.stroke()

drawCircle = (x, y, m) =>
    context.save()
    context.beginPath()
    context.arc(x, y, m, 0, 2 * Math.PI, false)
    context.fillStyle = 'rgba(0, 0, 255, 0.2)'
    context.strokeStyle = 'rgba(0, 0, 0, 0.2)'
    context.lineWidth = 1
    context.fill()
    context.stroke()
    context.restore()

drawPath = (path) =>
    context.strokeStyle = 'black'
    context.beginPath()
    context.moveTo(path[0]...)
    for pt in path
        context.lineTo(pt...)
    context.stroke()

simulate = (vector, steps, animationFunction) =>
    [m1, m2, l1, l2, Theta1_0, Theta2_0] = vector
    step = (Theta1, Theta2, dTheta1, dTheta2, d2Theta1, d2Theta2)=>
        mu = 1 + m1 / m2
        d2Theta1  =  (g*(Math.sin(Theta2)*Math.cos(Theta1-Theta2)-mu*Math.sin(Theta1))-(l2*dTheta2*dTheta2+l1*dTheta1*dTheta1*Math.cos(Theta1-Theta2))*Math.sin(Theta1-Theta2))/(l1*(mu-Math.cos(Theta1-Theta2)*Math.cos(Theta1-Theta2)))
        d2Theta2  =  (mu*g*(Math.sin(Theta1)*Math.cos(Theta1-Theta2)-Math.sin(Theta2))+(mu*l1*dTheta1*dTheta1+l2*dTheta2*dTheta2*Math.cos(Theta1-Theta2))*Math.sin(Theta1-Theta2))/(l2*(mu-Math.cos(Theta1-Theta2)*Math.cos(Theta1-Theta2)))
        dTheta1   += d2Theta1*time
        dTheta2   += d2Theta2*time
        Theta1    += dTheta1*time
        Theta2    += dTheta2*time
        return [Theta1, Theta2, dTheta1, dTheta2, d2Theta1, d2Theta2]

    X = [[Theta1_0, Theta2_0, 0, 0, 0, 0]]
    for i in [0..steps-1]
        X[i+1] = step X[i]...
        animationFunction X[i+1], vector if animationFunction?

path      = []
animation = []
animationInterval = null

animateAppend = (v, params) =>
    animation.push([v, params])

    unless animationInterval?
        animationInterval = setInterval =>
            v = animation.pop()
            if v?
                animate v...
            else
                path = []
                clearInterval animationInterval
                animationInterval = null
                runSimulation()
        , 10

animate = (v, params) =>
    context.clearRect(0, 0, canvas.width, canvas.height)
    [Theta1, Theta2] = v
    [m1, m2, l1, l2, Theta1_0, Theta2_0] = params
    x1 = X0 + l1 * Math.sin(Theta1)
    y1 = Y0 + l1 * Math.cos(Theta1)
    x2 = X0 + l1 * Math.sin(Theta1) + l2 * Math.sin(Theta2)
    y2 = Y0 + l1 * Math.cos(Theta1) + l2 * Math.cos(Theta2)

    path.push([x2, y2])

    drawLine(X0, Y0, x1, y1)
    drawLine(x1, y1, x2, y2)
    drawCircle(x1, y1, m1)
    drawCircle(x2, y2, m2)
    drawPath(path)


runSimulation = =>
    simulate [10, 10, 140, 140, Math.random() * 2 * Math.PI, Math.random() * 2 * Math.PI], 1000, animateAppend

runSimulation()
