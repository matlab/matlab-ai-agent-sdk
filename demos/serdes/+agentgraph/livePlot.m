function app = livePlot(graph)
%LIVEPLOT  Minimal live graph visualizer for an AgentGraph run.
%
%   APP = AGENTGRAPH.LIVEPLOT(GRAPH) opens a uifigure showing the graph nodes
%   as SVG circles connected by arrowed edges. Returns an object with methods
%   nodeRunning(name), nodeDone(name,result), nodeError(name,err) that the
%   engine calls during traversal (duck-typed observer).
%
%   Usage:
%       app = agentgraph.livePlot(graph);
%       graph.Observer = app;
%       graph.run(client, prompt, workspace, tools);

    names = graph.executionOrder();
    edges = graph.Edges;

    fig = uifigure( ...
        Name="AgentGraph — Live", ...
        Position=[100 100 900 500], ...
        Color=[0.12 0.12 0.12]);

    h = uihtml(fig, ...
        Position=[0 0 900 500], ...
        HTMLSource=graphHtml());

    % Build topology data for JS
    nNodes = numel(names);
    nodesData = cell(1, nNodes);
    for i = 1:nNodes
        node = graph.getNode(names(i));
        kind = "agent";
        if isa(node, 'agentgraph.FunctionNode')
            kind = "function";
        end
        nodesData{i} = struct( ...
            'id', names(i), ...
            'name', names(i), ...
            'x', i-1, ...
            'y', 0, ...
            'kind', kind);
    end

    edgesData = cell(1, size(edges,1));
    for i = 1:size(edges,1)
        edgesData{i} = struct('from', edges(i,1), 'to', edges(i,2));
    end

    h.Data = struct( ...
        'nodes', {nodesData}, ...
        'edges', {edgesData}, ...
        'title', graph.dependencyString(), ...
        'layout', 'grid');

    ready = false;
    buffer = {};
    h.HTMLEventReceivedFcn = @(~,evt) onReady(evt);

    % Return a struct that quacks like an observer
    app = struct( ...
        'nodeRunning', @(name) pushState(name, "running"), ...
        'nodeDone',    @(name, ~) pushState(name, "done"), ...
        'nodeError',   @(name, ~) pushState(name, "error"), ...
        'Figure',      fig);

    % --- Closures ---

    function onReady(evt)
        if evt.HTMLEventName == "ready"
            ready = true;
            for k = 1:numel(buffer)
                sendEventToHTMLSource(h, 'setState', buffer{k});
            end
            buffer = {};
        end
    end

    function pushState(id, state)
        msg = struct('id', id, 'state', state);
        if ready
            sendEventToHTMLSource(h, 'setState', msg);
        else
            buffer{end+1} = msg;
        end
        drawnow limitrate;
    end
end

%% =========================================================================

function html = graphHtml()
    lines = [
"<!DOCTYPE html>"
"<html>"
"<head>"
"<meta charset='utf-8'>"
"<style>"
"  html,body { margin:0; padding:0; height:100%; background:#1e1e1e; font-family:'Segoe UI',Arial,sans-serif; overflow:hidden; }"
"  #wrap { position:relative; width:100%; height:100%; }"
"  svg { width:100%; height:100%; display:block; }"
"  .edge { stroke:#8a8a8a; stroke-width:2; fill:none; marker-end:url(#arrow); }"
"  .nodeLabel { fill:#e6e6e6; font-size:14px; text-anchor:middle; pointer-events:none; }"
"  circle.node { stroke:#ffffff; stroke-width:2; }"
"  circle.unrun      { fill:#12395e; }"
"  circle.running    { fill:#2f8fd6; animation: blink 1s ease-in-out infinite; }"
"  circle.done       { fill:#2ecc71; animation:none; }"
"  circle.error      { fill:#e74c3c; animation:none; }"
"  @keyframes blink { 0%{opacity:1; fill:#2f8fd6;} 50%{opacity:0.4; fill:#8a8a8a;} 100%{opacity:1; fill:#2f8fd6;} }"
"  #title { position:absolute; left:10px; top:8px; color:#dddddd; font-size:13px; font-weight:600; pointer-events:none; }"
"</style>"
"</head>"
"<body>"
"  <div id='wrap'>"
"    <svg id='svg' viewBox='0 0 1000 400' preserveAspectRatio='xMidYMid meet'>"
"      <defs>"
"        <marker id='arrow' viewBox='0 0 10 10' refX='9' refY='5' markerWidth='7' markerHeight='7' orient='auto'>"
"          <path d='M0,0 L10,5 L0,10 z' fill='#8a8a8a'></path>"
"        </marker>"
"      </defs>"
"      <g id='edges'></g>"
"      <g id='nodes'></g>"
"    </svg>"
"    <div id='title'></div>"
"  </div>"
"<script type='text/javascript'>"
"function setup(htmlComponent) {"
"  const NS = 'http://www.w3.org/2000/svg';"
"  const gEdges = document.getElementById('edges');"
"  const gNodes = document.getElementById('nodes');"
"  const titleEl = document.getElementById('title');"
"  const svg = document.getElementById('svg');"
"  const R = 28;"
"  let pos = {};"
""
"  function draw(data) {"
"    gEdges.innerHTML = '';"
"    gNodes.innerHTML = '';"
"    pos = {};"
"    if (!data || !data.nodes) { return; }"
"    titleEl.textContent = data.title || '';"
"    const nodes = data.nodes;"
"    const edges = data.edges || [];"
"    const maxX = nodes.reduce(function(m,n){ return Math.max(m,n.x); }, 0);"
"    const W = (maxX+2)*190, H = 300;"
"    svg.setAttribute('viewBox', '0 0 ' + W + ' ' + H);"
"    nodes.forEach(function(n){ pos[n.id] = { x:(n.x+1)*190, y: H/2 }; });"
"    edges.forEach(function(e){"
"      const a = pos[e.from], b = pos[e.to];"
"      if (!a || !b) { return; }"
"      const dx=b.x-a.x, dy=b.y-a.y, len=Math.hypot(dx,dy)||1;"
"      const ux=dx/len, uy=dy/len;"
"      const x1=a.x+ux*R, y1=a.y+uy*R, x2=b.x-ux*(R+9), y2=b.y-uy*(R+9);"
"      const path = document.createElementNS(NS,'path');"
"      path.setAttribute('d','M'+x1+','+y1+' L'+x2+','+y2);"
"      path.setAttribute('class','edge');"
"      gEdges.appendChild(path);"
"    });"
"    nodes.forEach(function(n){"
"      const c = document.createElementNS(NS,'circle');"
"      c.setAttribute('cx',pos[n.id].x);"
"      c.setAttribute('cy',pos[n.id].y);"
"      c.setAttribute('r',R);"
"      c.setAttribute('class','node unrun');"
"      c.setAttribute('id','node-'+n.id);"
"      gNodes.appendChild(c);"
"      const t = document.createElementNS(NS,'text');"
"      t.setAttribute('x',pos[n.id].x);"
"      t.setAttribute('y',pos[n.id].y+R+17);"
"      t.setAttribute('class','nodeLabel');"
"      t.textContent = n.name;"
"      gNodes.appendChild(t);"
"    });"
"  }"
""
"  draw(htmlComponent.Data);"
"  htmlComponent.addEventListener('DataChanged', function(){ draw(htmlComponent.Data); });"
"  htmlComponent.addEventListener('setState', function(evt){"
"    const d = evt.Data || {};"
"    const c = document.getElementById('node-'+d.id);"
"    if (c) { c.setAttribute('class','node '+d.state); }"
"  });"
"  htmlComponent.sendEventToMATLAB('ready', '');"
"}"
"</script>"
"</body>"
"</html>"
    ];
    html = join(lines, newline);
end
