
# Location of the top of the pendulum
g  = 9.8
time = 0.05

canvas  = document.getElementById('simulation')
context = canvas.getContext('2d')
logArea = document.getElementById('log-area')

target = [[300, 400], [400, 200], [500, 400], [460, 300], [360, 300]]
drawTarget = =>
    context.save()
    context.strokeStyle = 'rgba(255, 0, 0, 0.2)'
    context.moveTo(target[0]...)
    for i in [1..target.length-1]
        context.lineTo(target[i]...)
    context.stroke()
    context.restore()

log = (message) ->
    log.number = (log.number or 0) + 1
    logArea.innerHTML = '<span class = "log-number">[' + log.number + ']</span> ' + message + '<br/>' + logArea.innerHTML

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
    [m1, m2, l1, l2, Theta1_0, Theta2_0, X0, Y0] = vector
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
    drawTarget()
    [Theta1, Theta2] = v
    [m1, m2, l1, l2, Theta1_0, Theta2_0, X0, Y0] = params
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
    log('Displaying best simulation.')
    simulate [10, 10, 140, 140, Math.random() * 2 * Math.PI, Math.random() * 2 * Math.PI, Math.random() * 600 + 200, Math.random() * 400 + 100], 1000, animateAppend

# --------------------- #
# The Genetic Algorithm #
# --------------------- #

targetSeq = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]

N = 20
MUTATION_CHANCE = 0.7
CROSSOVER_CHANCE = 1 - MUTATION_CHANCE
SAMPLE = 100

population = []
length = targetSeq.length
alphabet = targetSeq

choice = (array) =>
    """ Chooses a random element from an array. """
    array[Math.floor(Math.random() * array.length)]

window.generate_individual = =>
    """ Generates a random individual. """
    (choice(alphabet) for _ in [1..length])

window.mutate = (individual) =>
    """ Point-mutates an individual. """
    i = choice([1..length-1])
    if i == 0
        return [choice(alphabet)].concat(individual[1..-1])
    else if i == length-1
        return individual[1..-1].concat([choice(alphabet)])
    else
        return individual[0..i-1].concat([choice(alphabet)]).concat(individual[i+1..-1])

window.crossover = (individualA, individualB) =>
    """ Generates a new individual by double-crossover. """
crossover = (individualA, individualB) =>
    i = j = 0
    while i == j
        [i, j] = (choice([0..individualA.length]) for _ in [1, 2]).sort((a, b) -> a - b)
    alert([i, j]) if i >= j
    if i == 0
        individualB[0..j-1].concat(individualA[j..-1])
    else
        individualA[0..i-1].concat(individualB[i..j-1]).concat(individualA[j..-1])

zip = (a, b) =>
    ([a[i], b[i]] for i in [0..Math.min(a.length, b.length)-1])

window.fitness = (individual) =>
    """ Evaluates an individual's fitness. """
    zip(individual, targetSeq).map(([a, b]) -> a == b).reduce (a, b) -> a + b

elite = [generate_individual(), -1]

population = (generate_individual() for _ in [1..N])
log('Initial Population: <ul>' + population.map((x) -> "<li>#{x}</li>").join('') + '</ul>')
generation = 0
iterateGA = =>
    tng = (mutate choice population for _ in [1..Math.floor(1.1 * N * MUTATION_CHANCE)]).concat(
        (crossover(choice(population), choice(population)) for _ in [1..Math.floor(1.1 * N * CROSSOVER_CHANCE)]))

    fits = ([ind, fitness ind] for ind in tng).concat([elite]).sort((a, b) -> a[1] - b[1]).reverse()

    population = fits[0..N-1].map((x) -> x[0])

    if fits[0][1] > elite[1]
        elite = fits[0]

    generation += 1
    if generation % 100 == 0
        log('Generation ' + generation + '<br/> - Best individual: <span style = "color: red">"' + elite[0] +
            '"</span> (fitness ' + elite[1] + ')<br/>' +
            ' - Population: <ul>' + population.map((x) -> "<li>" + x + "</li>").join('') + "</ul>")
    if elite[0] != targetSeq
        setTimeout iterateGA, 10
    else
        log("Found target after #{generation} generations!")
#iterateGA()
# ---

runSimulation()
