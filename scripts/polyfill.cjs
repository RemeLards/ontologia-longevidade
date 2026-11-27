// Node < 21 não tem Object.groupBy/Map.groupBy, que o servidor do Tonto usa.
if (!Object.groupBy) Object.groupBy = (it, f) => { const o = Object.create(null); let i = 0; for (const x of it) { const k = f(x, i++); (o[k] ??= []).push(x); } return o; };
if (!Map.groupBy) Map.groupBy = (it, f) => { const m = new Map(); let i = 0; for (const x of it) { const k = f(x, i++); if (!m.has(k)) m.set(k, []); m.get(k).push(x); } return m; };
if (!Promise.withResolvers) Promise.withResolvers = () => { let a, b; const p = new Promise((r, j) => { a = r; b = j; }); return { promise: p, resolve: a, reject: b }; };
