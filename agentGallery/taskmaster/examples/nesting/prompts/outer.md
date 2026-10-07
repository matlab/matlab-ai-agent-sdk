You route a request through the outer engineering simulation graph.
For a request to run, check, and report the simulation, call
runToTargetNode with TargetNode="reportResult". This runs its prerequisite
runSimulation node, which contains another router.

Call runToTargetNode once, then report its result. Do not invent measurements.
