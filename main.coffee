
PATH_LENGTH = 500

# Location of the top of the pendulum
g  = 9.8
time = 0.05

canvas  = document.getElementById('simulation')
context = canvas.getContext('2d')
logArea = document.getElementById('log-area')

targetPoints = [[400, 400], [500, 200], [600, 400], [560, 300], [460, 300]]
drawTarget = =>
    context.save()
    context.strokeStyle = 'rgba(255, 0, 0, 0.1)'
    context.moveTo(targetPoints[0]...)
    for i in [1..targetPoints.length-1]
        context.lineTo(targetPoints[i]...)
    context.stroke()
    context.restore()

pairwise = (array) ->
    ([array[i], array[i+1]] for i in [0..array.length-2])

euclideanDistance = ([x1, y1], [x2, y2]) ->
    dx = x2 - x1
    dy = y2 - y1
    Math.sqrt(dx * dx + dy * dy)

euclideanDistance2 = ([x1, y1], [x2, y2]) ->
    dx = x2 - x1
    dy = y2 - y1
    dx * dx + dy * dy

window.log = (message...) ->
    log.number = (log.number or 0) + 1
    logArea.innerHTML = '<span class = "log-number">[' + ('     ' + log.number).slice(-5) + ']</span> ' + message.join('<br/>        ') + '<br/><br/>' + logArea.innerHTML

eLength = pairwise(targetPoints).
    map(([pt1, pt2]) -> euclideanDistance(pt1, pt2)).
    reduce((a, b) -> a + b)

target = []

ds = eLength / PATH_LENGTH
for [r1, r2] in pairwise(targetPoints)
    [[x1, y1], [x2, y2]] = [r1, r2]
    dx = x2 - x1
    dy = y2 - y1
    r = euclideanDistance r1, r2
    for i in [0..Math.floor(r / ds)]
        target.push([x1 + i * ds * dx / r, y1 + i * ds * dy / r])

maxWidth = (points) ->
    xs = points.map(([x, _]) -> x)
    xs.reduce((a, b) -> Math.max(a, b)) - xs.reduce((a, b) -> Math.min(a, b))

maxHeight = (points) ->
    ys = points.map(([_, y]) -> y)
    ys.reduce((a, b) -> Math.max(a, b)) - ys.reduce((a, b) -> Math.min(a, b))

targetWidth  = maxWidth targetPoints
targetHeight = maxHeight targetPoints

drawLine = (x1, y1, x2, y2) =>
    context.strokeStyle = 'rgba(0, 0, 0, 0.1)'
    context.beginPath()
    context.moveTo(x1, y1)
    context.lineTo(x2, y2)
    context.stroke()

drawCircle = (x, y, m, fillStyle = 'rgba(0, 0, 255, 0.1)', strokeStyle = 'rgba(0, 0, 0, 0.1)') =>
    context.save()
    context.beginPath()
    context.arc(x, y, m, 0, 2 * Math.PI, false)
    context.fillStyle = fillStyle
    context.strokeStyle = strokeStyle
    context.lineWidth = 1
    context.fill() if fillStyle?
    context.stroke() if strokeStyle?
    context.restore()

drawPath = (path) =>
    context.strokeStyle = 'black'
    context.beginPath()
    context.moveTo(path[0]...)
    for pt in path
        context.lineTo(pt...)
    context.stroke()

simulate = (vector, steps, animationFunction) =>
    [m1, m2, l1, l2, Theta1_0, Theta2_0, X0, Y0, g] = vector
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
    X

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
        , 5

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
    drawCircle(X0, Y0, 2, 'rgba(0, 0, 0, 0.1)', null)
    drawPath(path)

ffwd = false

runSimulation = =>
    #simulate [10, 10, 140, 140, Math.random() * 2 * Math.PI, Math.random() * 2 * Math.PI, Math.random() * 600 + 200, Math.random() * 400 + 100], 1000, animateAppend
    simulate elite[0].slice(0), PATH_LENGTH, animateAppend
    iterateGA()
    if ffwd
        log('The last three settings were the same. <span style = "color: blue; font-weight: bold;">Fast-forwarding...</span>')
        while ffwd
            iterateGA()

# --------------------- #
# The Genetic Algorithm #
# --------------------- #

N = 15
MUTATION_CHANCE = 0.8
CROSSOVER_CHANCE = 1 - MUTATION_CHANCE
ELITE_CHANCE = 0.25
SAMPLE = 100

population = []
length = 9

minimum = [5, 5, 10, 20, 0, 0, 200, 100, 1]
maximum = [50, 50, 250, 250, 2 * Math.PI, 2 * Math.PI, 800, 500, 20]

Array::shuffle ?= ->
  if @length > 1 then for i in [@length-1..1]
    j = Math.floor Math.random() * (i + 1)
    [@[i], @[j]] = [@[j], @[i]]
  this

enforce_bounds = (individual) =>
    """ Limits the individual to  values no lower than the min and values no higher than the max. """
    (Math.min(Math.max(individual[i], minimum[i]), maximum[i]) for i in [0..individual.length-1])

choice = (array) =>
    array[Math.floor(Math.random() * array.length)]

window.random_value = (i) =>
    """ Chooses a random element from a range. """
    Math.random() * (maximum[i] - minimum[i]) + minimum[i]

window.generate_individual = =>
    """ Generates a random individual. """
    (random_value(i) for i in [0..length-1])

window.mutate = (individual) =>
    """ Point-mutates an individual. """
    i = choice([1..length-1])
    if i == 0
        return enforce_bounds([random_value(0)].concat(individual[1..-1]))
    else if i == length-1
        return enforce_bounds(individual[1..-1].concat([random_value(i)]))
    else
        return enforce_bounds(individual[0..i-1].concat([random_value(i)]).concat(individual[i+1..-1]))

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
    [m1, m2, l1, l2, th1_0, th2_0, X0, Y0, g] = individual
    v = simulate individual, PATH_LENGTH, null
    x2 = v.map(([th1, th2]) -> X0 + l1 * Math.sin(th1) + l2 * Math.sin(th2))
    y2 = v.map(([th1, th2]) -> Y0 + l1 * Math.cos(th1) + l2 * Math.cos(th2))
    pts = zip x2, y2
    dwidth  = Math.abs((targetWidth - maxWidth(pts)) / targetWidth)
    dheight = Math.abs((targetHeight - maxHeight(pts)) / targetHeight)
    square = (x) -> x * x
    -1 * Math.log zip(pts, target).
        map(([a, b]) -> euclideanDistance2(a, b)).
        reduce((a, b) -> a + b) *
        Math.sqrt(dwidth * dheight) / PATH_LENGTH

roundAll = (x) ->
    x.map Math.round

round3 = (x) ->
    Math.round(x * 1000) / 1000

roundAll3 = (x) ->
    x.map round3

SMAP_INTERVAL = 100
smap_task = null
smap_queue = []

# Scheduled map; only fires an event every so often.
Array::smap = (fn) ->
    smap_queue.push([this, fn, 0, []])
    if not smap_task?
        smap_task = set_timeout ->
            if smap_queue.length == 0
                smap_task = null
                return
            [array, task, i] = smap_queue.pop()
            task(array[i])
        , SMAP_INTERVAL

oldElites = []
elite = [generate_individual(), -10000000]

population = (generate_individual() for _ in [1..N])
log(
    '<b>*** Welcome to the Double Pendulum GA ***</b>',
    '',
    '<a href = "bitcoin:1AzPZLiq5hmNjt8jmezXaueoABd9LjvvQQ">1AzPZLiq5hmNjt8jmezXaueoABd9LjvvQQ</a>',
    '',
    "N = #{N}",
    "MUTATION_CHANCE  = #{MUTATION_CHANCE}",
    "CROSSOVER_CHANCE = #{CROSSOVER_CHANCE}",
    "ELITE_CHANCE     = #{ELITE_CHANCE}",
    "PATH_LENGTH      = #{PATH_LENGTH}",
    'population       =',
    population.map((x) -> "  [#{roundAll3(x).join(', ')}]")...)
#log('Initial Population: <ul>' + population.map((x) -> "<li>#{roundAll x}</li>").join('') + '</ul>')
generation = 0
iterateGA = =>
    tng = (mutate choice population for _ in [1..Math.floor(1.5 * N * MUTATION_CHANCE)]).concat(
        (crossover(choice(population), choice(population)) for _ in [1..Math.floor(1.5 * N * CROSSOVER_CHANCE)]))

    fits = ([ind, fitness ind] for ind in tng).concat(if Math.random() < ELITE_CHANCE then [elite] else []).shuffle().sort((a, b) -> a[1] - b[1]).reverse()

    population = fits[0..N-1].map((x) -> x[0])

    if fits[0][1] > elite[1]
        elite = fits[0]

    if oldElites.length >= 3
        ffwd = (elite == oldElites.pop(0))
    oldElites.push(elite)

    generation += 1
    if not ffwd
        labels = ['m<sub>1</sub>', 'm<sub>2</sub>', 'L<sub>1</sub>', 'L<sub>2</sub>', '&theta;<sub>1</sub>',
            '&theta;<sub>2</sub>', 'x<sub>0</sub>', 'y<sub>0</sub>', 'g']
        bestIndividual1 = zip(labels[0..3], roundAll3(elite[0][0..3])).map(([a, b]) -> "#{a} = #{b}").join(', ')
        bestIndividual2 = zip(labels[4..-1], roundAll3(elite[0][4..-1])).map(([a, b]) -> "#{a} = #{b}").join(', ')
        if generation % 100 == 1
            log("<i>Generation #{generation}</i>",
                '- Best individual: <span style = "color: red">',
                bestIndividual1,
                bestIndividual2,
                '</span>  (fitness ' + round3(elite[1]) + ')',
                '- Population: ',
                fits[0..N-1].map(([ind, fit]) -> "    [#{roundAll3(ind).join(', ')}] (#{round3 fit})")...)
        else
            log("<i>Generation #{generation}</i>",
                "- Best Individual: <span style = 'color: red;'>",
                "  #{bestIndividual1}",
                "  #{bestIndividual2}",
                "</span>  (fitness #{round3 elite[1]})")
#    setTimeout iterateGA, 10000
iterateGA()
# ---

runSimulation()
