var prev = null;
var pips = [];

workspace.windowActivated.connect(function (w) {
    if (!w) return;

    if (/Picture.in.Picture/i.test(w.caption)) {
        var pip = pips.find(function (p) { return p.w === w; });
        if (!pip) {
            pip = { w: w, t: Date.now() };
            pips.push(pip);
        }
        if (Date.now() - pip.t < 1000 && prev && !prev.deleted) {
            workspace.activeWindow = prev;
        }
        return;
    }

    prev = w;
});
